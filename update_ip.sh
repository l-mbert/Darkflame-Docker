#!/bin/bash

EXTERNAL_IP=$(/sbin/ip route|awk '/default/ { print $3 }')
ex -s -c '%s/external_ip=localhost/external_ip='"$EXTERNAL_IP"'/g|x' /DarkflameServer/build/masterconfig.ini
ex -s -c '%s/external_ip=localhost/external_ip='"$EXTERNAL_IP"'/g|x' /DarkflameServer/build/authconfig.ini
ex -s -c '%s/external_ip=localhost/external_ip='"$EXTERNAL_IP"'/g|x' /DarkflameServer/build/chatconfig.ini