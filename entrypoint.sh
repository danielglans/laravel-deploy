#!/bin/bash

mkdir -p /root/.ssh
ssh-keyscan -H "$2" >> /root/.ssh/known_hosts

if [ -z "$DEPLOY_KEY" ];
then
	echo $'\n' "------ DEPLOY KEY NOT SET YET! ----------------" $'\n'
	exit 1
else
	printf '%b\n' "$DEPLOY_KEY" > /root/.ssh/id_rsa
	chmod 400 /root/.ssh/id_rsa

	echo $'\n' "------ CONFIG SUCCESSFUL! ---------------------" $'\n'
fi

rsync --progress -avzh \
	--exclude='.git/' \
	--exclude='.git*' \
	--exclude='.editorconfig' \
	--exclude='.styleci.yml' \
	--exclude='.idea/' \
	--exclude='Dockerfile' \
	--exclude='readme.md' \
	--exclude='README.md' \
	--exclude='storage/oauth-*' \
	-e "ssh -i /root/.ssh/id_rsa" \
	--rsync-path="sudo rsync" . $1@$2:$3

if [ $? -eq 0 ]
then

	if [ $6 ]
	then
	echo $'\n' "------ SET APPROPIATE PHP BIN -------------------" $'\n'
	
	php=/usr/local/lsws/lsphp74/bin/php7.4
	
	else
	
	php=php
	
	fi

	echo $'\n' "------ SYNC SUCCESSFUL! -----------------------" $'\n'
	echo $'\n' "------ RELOADING PERMISSION -------------------" $'\n'

	ssh -i /root/.ssh/id_rsa -t $1@$2 "sudo chown -R $4:$5 $3"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "sudo chmod 775 -R $3"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "sudo chmod 777 -R $3/storage"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "sudo chmod 777 -R $3/public"
	
	echo $'\n' "------ OPTIMIZE DEPLOY -------------------" $'\n'
	
	ssh -i /root/.ssh/id_rsa -t $1@$2 "cd $3 && $php artisan migrate --force"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "cd $3 && $php artisan optimize:clear"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "cd $3 && $php artisan config:cache"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "cd $3 && $php artisan queue:restart"
	
	if [ $6 ]
	then
	echo $'\n' "------ RELOAD LIGHTSPEED -------------------" $'\n'
	
	ssh -i /root/.ssh/id_rsa -t $1@$2 "/root/.brighthub/brighthub.sh web-restart"
	
	fi

	echo $'\n' "------ CONGRATS! DEPLOY SUCCESSFUL!!! ---------" $'\n'
	exit 0
else
	echo $'\n' "------ DEPLOY FAILED! -------------------------" $'\n'
	exit 1
fi
