#!/bin/bash

sed -i "s/{PORT}/$PORT/g" /etc/apache2/apache2.conf
mkdir /var/lock/apache2
mkdir /var/run/apache2

exec php-fpm -F & exec /usr/sbin/apache2ctl -D FOREGROUND
