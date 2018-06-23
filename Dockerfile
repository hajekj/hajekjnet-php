FROM php:7.2.5-apache
MAINTAINER Jan Hajek <hajek.j@hotmail.com>

COPY apache2.conf /bin/
COPY rpaf.conf /bin/
COPY init_container.sh /bin/

RUN a2enmod rewrite expires include deflate

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         libpng-dev \
         libjpeg-dev \
         libpq-dev \
         libmcrypt-dev \
         libldap2-dev \
         libldb-dev \
         libicu-dev \
         libgmp-dev \
         libmagickwand-dev \
         openssh-server vim curl wget tcptraceroute \
    && chmod 755 /bin/init_container.sh \
    && echo "cd /home" >> /etc/bash.bashrc \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install imagick-beta \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd \
         mysqli \
         opcache \
         pdo \
         pdo_mysql \
         pdo_pgsql \
         pgsql \
         ldap \
         intl \
         gmp \
         zip \
         bcmath \
         mbstring \
         pcntl \
    && docker-php-ext-enable imagick \
    && docker-php-ext-enable mcrypt

# Install RPAF as per https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-as-a-web-server-and-reverse-proxy-for-apache-on-one-ubuntu-16-04-server
RUN \
   apt-get update \
   && apt-get install -y --no-install-recommends \
        unzip build-essential apache2-dev \
   && wget https://github.com/gnif/mod_rpaf/archive/stable.zip \
   && unzip stable.zip \
   && cd mod_rpaf-stable \
   && make \
   && make install \
   && echo "LoadModule rpaf_module /usr/lib/apache2/modules/mod_rpaf.so" >> /etc/apache2/mods-enabled/rpaf.load \
   && cp /bin/rpaf.conf /etc/apache2/mods-enabled/rpaf.conf

RUN   \
   rm -f /var/log/apache2/* \
   && rmdir /var/lock/apache2 \
   && rmdir /var/run/apache2 \
   && rmdir /var/log/apache2 \
   && chmod 777 /var/log \
   && chmod 777 /var/run \
   && chmod 777 /var/lock \
   && chmod 777 /bin/init_container.sh \
   && cp /bin/apache2.conf /etc/apache2/apache2.conf \
   && rm -rf /var/www/html \
   && rm -rf /var/log/apache2 \
   && mkdir -p /home/LogFiles \
   && ln -s /home/site/wwwroot /var/www/html \
   && ln -s /home/LogFiles /var/log/apache2 

RUN { \
                echo 'opcache.memory_consumption=64'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
                echo 'error_log=/var/log/apache2/php-error.log'; \
                echo 'display_errors=Off'; \
                echo 'log_errors=On'; \
                echo 'display_startup_errors=Off'; \
                echo 'date.timezone=UTC'; \
    } > /usr/local/etc/php/conf.d/php.ini

EXPOSE 8080

ENV PORT 8080

WORKDIR /var/www/html

ENTRYPOINT ["/bin/init_container.sh"]
