FROM centos:7

RUN mkdir -p /usr/local/src
RUN yum install -y wget gcc make automake autoconf

ENV PHP_VERSION 7.1.5

RUN wget -O /usr/local/src/php-$PHP_VERSION.tar.gz http://cn2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror
RUN tar -xzf /usr/local/src/php-$PHP_VERSION.tar.gz -C /usr/local/src

RUN wget -O /usr/local/src/libiconv-1.15.tar.gz http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
RUN tar -xzf /usr/local/src/libiconv-1.15.tar.gz -C /usr/local/src

RUN yum install -y libtool

RUN cd /usr/local/src/libiconv-1.15 \
    && ./configure --prefix=/usr/local/libiconv  \
    && make && make install \
    && libtool --finish /usr/local/libiconv/lib \
    && ls -al /usr/local/libiconv 

RUN yum install -y libxml2 libxml2-devel gmp-devel
RUN yum install -y libzip-devel zlib-devel bzip2-devel gettext-devel libcurl-devel gd-devel openssl-devel 

RUN wget -O /usr/local/src/epel-release-6-8.noarch.rpm http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \
    && wget -O /usr/local/src/remi-release-6.rpm http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
    && rpm -Uvh /usr/local/src/remi-release-6*.rpm /usr/local/src/epel-release-6*.rpm \
    && yum install -y libmcrypt-devel \
    && yum install -y libmhash-devel

# RUN wget -O /usr/local/src/libmcrypt-2.6.8.tar.gz https://ncu.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
# RUN tar -xzf /usr/local/src/libmcrypt-2.6.8.tar.gz -C /usr/local/src
# RUN cd /usr/local/src/libmcrypt-2.6.8 \
#    && ./configure \
#    && make \
#    && make install

RUN yum install -y readline-devel

RUN yum install -y libxslt libxslt-devel

# for apache
RUN yum install -y httpd httpd-devel

ENV PHP_PREFIX /usr
ENV PHP_CONFIG_FILE_PATH /etc

RUN cd /usr/local/src/php-$PHP_VERSION \
    && ./configure \
        --prefix=$PHP_PREFIX \
        --with-config-file-path=$PHP_CONFIG_FILE_PATH \
        --with-config-file-scan-dir=$PHP_CONFIG_FILE_PATH/php.d \
        --with-apxs2=/usr/bin/apxs \
        --enable-opcache \
        --enable-mbstring \
        --enable-zip \
        --enable-bcmath \
        --enable-pcntl \
        --enable-ftp \
        --enable-calendar \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-wddx \
        --enable-exif \
        --enable-shmop \
        --enable-soap \
        --enable-sockets \
        --with-curl \
        --with-mcrypt \
        --with-iconv=/usr/local/libiconv \
        --with-gmp \
        --with-openssl \
        --with-readline \
        --with-zlib=/usr \
        --with-bz2=/usr \
        --with-gettext=/usr \
        --with-mysql=mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-gd \
        --with-jpeg-dir=/usr \
        --with-png-dir=/usr \
        --with-xmlrpc \
        --with-xsl \
        --with-readline \
        # --with-imap \
        # --with-ldap \
    && make  \
    # && make test \
    && make install 

RUN mkdir -p $PHP_CONFIG_FILE_PATH/php.d
RUN cp /usr/local/src/php-$PHP_VERSION/php.ini-production $PHP_CONFIG_FILE_PATH/php.ini

ENV PECL $PHP_PREFIX/bin/pecl
RUN $PECL install redis && echo "exstension=redis.so" > $PHP_CONFIG_FILE_PATH/php.d/redis.ini
RUN $PECL install igbinary && echo "exstension=igbinary.so" > $PHP_CONFIG_FILE_PATH/php.d/igbinary.ini
RUN $PECL install inotify && echo "exstension=inotify.so" > $PHP_CONFIG_FILE_PATH/php.d/inotify.ini

RUN yum install -y ImageMagick ImageMagick-devel
RUN $PECL install imagick && echo "exstension=imagick.so" > $PHP_CONFIG_FILE_PATH/php.d/imagick.ini

# # !FAILED: /usr/local/src/memcached-3.0.3/php_libmemcached_compat.h:31: error: expected '=', ',', ';', 'asm' or '__attribute__' before 'php_memcached_instance_st'
# RUN yum install -y libmemcached libmemcached-devel
# RUN wget -O /usr/local/src/memcached-3.0.3.tgz https://pecl.php.net/get/memcached-3.0.3.tgz \
#     && tar xzf /usr/local/src/memcached-3.0.3.tgz -C /usr/local/src \
#     && cd /usr/local/src/memcached-3.0.3 \
#     && $PHP_PREFIX/bin/phpize \
#     && ./configure --with-php-config=$PHP_PREFIX/bin/php-config --with-libmemcached-dir=/usr/local/libmemcached/ --disable-memcached-sasl \
#     && make \
#     && make install \
#     && echo "exstension=memcached.so" > $PHP_CONFIG_FILE_PATH/php.d/memcached.ini

# RUN php -v && php -m | sort

RUN sed 's|;opcache.enable|opcache.enable|' -i $PHP_CONFIG_FILE_PATH/php.ini \
    && echo 'zend_extension=opcache.so' > $PHP_CONFIG_FILE_PATH/php.d/opcache.ini 

RUN rm -f /var/www/html/index.html \
    && echo '<?php phpinfo();' > /var/www/html/index.php \
    && sed 's|logs/access_log|/dev/stdout|' -i /etc/httpd/conf/httpd.conf \
    && sed 's|logs/error_log|/dev/stderr|' -i /etc/httpd/conf/httpd.conf \
    && echo '# Enable php7 to deal .php files.' > /etc/httpd/conf.d/php.conf \
    && echo 'AddHandler php7-script .php' >> /etc/httpd/conf.d/php.conf \
    && echo 'AddType text/html .php' >> /etc/httpd/conf.d/php.conf \
    && echo 'DirectoryIndex index.php' >> /etc/httpd/conf.d/php.conf \
    && yum clean all 

EXPOSE 80 443

CMD [ "/usr/sbin/httpd", "-DFOREGROUND" ]

