# besn's Debian+Nginx4Yii2 Environment (with some extras)

Simple docker image based on Debian stretch which includes nginx, PHP 7.2, Memcached and tools to bootstrap building frontend and backend applications

## Start the environment

	docker run --name <container name> besn/yii2-environment:latest

## Run commands in the docker container

 	docker run --rm -ti besn/yii2-environment:latest bash
    
or
    
  	docker exec -ti <container name> bash

## Use the image in your GitLab CI build

Add `image: besn/yii2-environment:latest` to your `.gitlab-ci.yml` and use `node`, `npm`, `yarn` or `composer` commands for your build or test tasks
