#!/bin/bash

APP_URL=$(heroku info | grep 'Web URL:' | awk '{print $3}')
DOMAIN=${APP_URL#https://}
DOMAIN=${DOMAIN%/}

heroku config:set PHX_HOST=$DOMAIN
