FROM debian:stretch

MAINTAINER Andi Mery <besn@besn.at>

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# setup the debian apt sources
RUN echo 'deb http://deb.debian.org/debian/ stretch main non-free contrib\n\
deb http://security.debian.org/ stretch/updates main contrib non-free\n\
deb http://deb.debian.org/debian/ stretch-updates main contrib non-free\n\
deb http://deb.debian.org/debian/ stretch-backports main contrib non-free\n\
\n'\
> /etc/apt/sources.list

# update the package list
RUN /usr/bin/apt-get update -q

# upgrade the installed packages
RUN /usr/bin/apt-get upgrade -yqq

# install and setup locales
RUN /usr/bin/apt-get -yqq install locales && \
    /bin/sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
    /usr/sbin/dpkg-reconfigure locales && \
    /usr/sbin/locale-gen && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# install some packages we need
RUN /usr/bin/apt-get install -yqq openssh-client curl apt-transport-https software-properties-common lsb-release ca-certificates gnupg pwgen

# setup deb.sury.org (php7+) apt source
RUN ["/bin/bash", "-c", "set -o pipefail && /usr/bin/curl -L https://packages.sury.org/php/apt.gpg 2>/dev/null | /usr/bin/apt-key add -"]
RUN /usr/bin/add-apt-repository "deb [arch=amd64] https://packages.sury.org/php/ $(lsb_release -sc) main"

# setup phalcon-php apt source
RUN ["/bin/bash", "-c", "set -o pipefail && /usr/bin/curl -L https://packagecloud.io/phalcon/stable/gpgkey 2>/dev/null | /usr/bin/apt-key add -"]
RUN /usr/bin/add-apt-repository "deb [arch=amd64] https://packagecloud.io/phalcon/stable/debian/ $(lsb_release -sc) main"

# setup nodesource (nodejs) apt source
RUN ["/bin/bash", "-c", "set -o pipefail && /usr/bin/curl -L https://deb.nodesource.com/gpgkey/nodesource.gpg.key 2>/dev/null | /usr/bin/apt-key add -"]
RUN /usr/bin/add-apt-repository "deb [arch=amd64] https://deb.nodesource.com/node_9.x $(lsb_release -sc) main"

# setup yarnpkg apt source
RUN ["/bin/bash", "-c", "set -o pipefail && /usr/bin/curl -L https://dl.yarnpkg.com/debian/pubkey.gpg 2>/dev/null | /usr/bin/apt-key add -"]
RUN /usr/bin/add-apt-repository "deb [arch=amd64] https://dl.yarnpkg.com/debian/ stable main"

# update the package list
RUN /usr/bin/apt-get update -q

# install more packages
RUN /usr/bin/apt-get install -yqq rsync git wget supervisor nginx memcached nodejs yarn unzip mysql-client make gcc libpng-dev \
    php7.2-bz2 php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php7.2-imap php7.2-intl php7.2-json php7.2-mbstring php7.2-mysql php7.2-mongodb php7.2-opcache php7.2-readline php7.2-soap php7.2-xml php7.2-zip \
    php-apcu php-geoip php-mailparse php-memcached php-pear

# cleanup
RUN /usr/bin/apt-get clean \
    && /bin/rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && /usr/bin/apt-get purge -yqq unattended-upgrades dmsetup \
    && /usr/bin/apt-get autoremove -yqq

# setup supervisor
RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:php-fpm]\n\
command=/usr/sbin/php7.2-fpm -F\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:nginx]\n\
command=/usr/sbin/nginx\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:memcached]\n\
command=/usr/bin/memcached -p 11211 -u memcached -m 64 -c 1024 -t 1\n\
autostart=true\n\
autorestart=true\n\
\n'\
> /etc/supervisor/supervisord.conf

# download and install composer
RUN /usr/bin/curl -s --output /usr/bin/composer https://getcomposer.org/composer.phar && \
    /bin/chmod +x /usr/bin/composer

# disable services
RUN /usr/sbin/service supervisor stop && \
    /usr/sbin/service memcached stop && \
    /usr/sbin/service php7.2-fpm stop && \
    /usr/sbin/service nginx stop && \
    /usr/sbin/update-rc.d -f supervisor remove && \
    /usr/sbin/update-rc.d -f memcached remove && \
    /usr/sbin/update-rc.d -f nginx remove && \
    /usr/sbin/update-rc.d -f php7.2-fpm remove

# start supervisord
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
