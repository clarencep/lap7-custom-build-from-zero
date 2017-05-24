FROM centos:7


RUN yum install -y wget gcc make automake autoconf

ENV SRC_DIR /data/server/src
ENV PHP_VERSION 7.1.5
ENV HTTPD_VERSION 2.4.25
ENV HTTPD_PREFIX /data/server/httpd-$HTTPD_VERSION

ENV PHP_PREFIX /data/server/php-$PHP_VERSION
ENV PHP_CONFIG_FILE_PATH $PHP_PREFIX/etc

RUN mkdir -p $SRC_DIR

RUN wget -O $SRC_DIR/php-$PHP_VERSION.tar.gz http://cn2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
    && tar -xzf $SRC_DIR/php-$PHP_VERSION.tar.gz -C $SRC_DIR \
    && rm -f $SRC_DIR/php-$PHP_VERSION.tar.gz

RUN wget -O $SRC_DIR/libiconv-1.15.tar.gz http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz \
    && tar -xzf $SRC_DIR/libiconv-1.15.tar.gz -C $SRC_DIR \
    && rm -f $SRC_DIR/libiconv-1.15.tar.gz

RUN wget -O $SRC_DIR/httpd-$HTTPD_VERSION.tar.gz http://mirror.bit.edu.cn/apache//httpd/httpd-$HTTPD_VERSION.tar.gz \
    && tar -xzf $SRC_DIR/httpd-$HTTPD_VERSION.tar.gz -C $SRC_DIR \
    && rm -f $SRC_DIR/httpd-$HTTPD_VERSION.tar.gz

RUN wget -O $SRC_DIR/apr-1.5.2.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache//apr/apr-1.5.2.tar.gz \
    && tar -xzf $SRC_DIR/apr-1.5.2.tar.gz -C $SRC_DIR \
    && rm -f $SRC_DIR/apr-1.5.2.tar.gz

RUN wget -O $SRC_DIR/apr-util-1.5.4.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache//apr/apr-util-1.5.4.tar.gz \
    && tar -xzf $SRC_DIR/apr-util-1.5.4.tar.gz -C $SRC_DIR \
    && rm -f $SRC_DIR/apr-util-1.5.4.tar.gz

RUN wget -O $SRC_DIR/apr-iconv-1.2.1.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache//apr/apr-iconv-1.2.1.tar.gz \
    && tar -xzf $SRC_DIR/apr-iconv-1.2.1.tar.gz -C $SRC_DIR \
    && rm -f $SRC_DIR/apr-iconv-1.2.1.tar.gz

RUN yum install -y libxml2 libxml2-devel gmp-devel \
                   libzip-devel zlib-devel bzip2-devel \
                   gettext-devel libcurl-devel gd-devel openssl-devel \
                   readline-devel libxslt libxslt-devel \
                   libtool

RUN cd $SRC_DIR/libiconv-1.15 \
    && ./configure --prefix=/usr/local/libiconv  \
    && make && make install \
    && libtool --finish /usr/local/libiconv/lib \
    && ls -al /usr/local/libiconv 

RUN cd $SRC_DIR/apr-1.5.2 \
    && ./configure \
          --prefix=$HTTPD_PREFIX/apr \
    && make \
    && mkdir -p $HTTPD_PREFIX $HTTPD_PREFIX/apr \
    && make install 
    
RUN cd $SRC_DIR/apr-util-1.5.4 \
    && ./configure \
          --prefix=$HTTPD_PREFIX/apr-util \
          --with-apr=$HTTPD_PREFIX/apr \
    && make \
    && mkdir -p $HTTPD_PREFIX $HTTPD_PREFIX/apr-util \
    && make install 

RUN cd $SRC_DIR/apr-iconv-1.2.1 \
    && ./configure \
          --prefix=$HTTPD_PREFIX/apr-iconv \
          --with-apr=$HTTPD_PREFIX/apr \
    && make \
    && mkdir -p $HTTPD_PREFIX $HTTPD_PREFIX/apr-iconv \
    && make install 

RUN yum install -y pcre pcre-devel

RUN cd $SRC_DIR/httpd-$HTTPD_VERSION \
    && ./configure \
          --prefix=$HTTPD_PREFIX \
          --with-apr=$HTTPD_PREFIX/apr \
          --with-apr-util=$HTTPD_PREFIX/apr-util \
          --enable-mods-shared=all \
        #   --enable-rewrite \
        #   --enable-proxy \
        #   --enable-proxy-http \
        #   --enable-ssl \
        #   --enable-http2 \
        #   --enable-proxy-http2 \
    && make \
    && make install 


RUN wget -O $SRC_DIR/epel-release-6-8.noarch.rpm http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \
    && wget -O $SRC_DIR/remi-release-6.rpm http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
    && rpm -Uvh $SRC_DIR/remi-release-6*.rpm $SRC_DIR/epel-release-6*.rpm \
    && yum install -y libmcrypt-devel \
    && yum install -y libmhash-devel \
    && rm -f $SRC_DIR/remi-release-6*.rpm $SRC_DIR/epel-release-6*.rpm 

# RUN wget -O $SRC_DIR/libmcrypt-2.6.8.tar.gz https://ncu.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
# RUN tar -xzf $SRC_DIR/libmcrypt-2.6.8.tar.gz -C $SRC_DIR
# RUN cd $SRC_DIR/libmcrypt-2.6.8 \
#    && ./configure \
#    && make \
#    && make install

# for apache
# RUN yum install -y httpd httpd-devel


RUN cd $SRC_DIR/php-$PHP_VERSION \
    && ./configure \
        --prefix=$PHP_PREFIX \
        --with-config-file-path=$PHP_CONFIG_FILE_PATH \
        --with-config-file-scan-dir=$PHP_CONFIG_FILE_PATH/php.d \
        --with-apxs2=$HTTPD_PREFIX/bin/apxs \
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
RUN cp $SRC_DIR/php-$PHP_VERSION/php.ini-production $PHP_CONFIG_FILE_PATH/php.ini

ENV PECL $PHP_PREFIX/bin/pecl
RUN $PECL install redis && echo "extension=redis.so" > $PHP_CONFIG_FILE_PATH/php.d/redis.ini
RUN $PECL install igbinary && echo "extension=igbinary.so" > $PHP_CONFIG_FILE_PATH/php.d/igbinary.ini
RUN $PECL install inotify && echo "extension=inotify.so" > $PHP_CONFIG_FILE_PATH/php.d/inotify.ini

RUN yum install -y ImageMagick ImageMagick-devel
RUN $PECL install imagick && echo "extension=imagick.so" > $PHP_CONFIG_FILE_PATH/php.d/imagick.ini

# # !FAILED: $SRC_DIR/memcached-3.0.3/php_libmemcached_compat.h:31: error: expected '=', ',', ';', 'asm' or '__attribute__' before 'php_memcached_instance_st'
# RUN yum install -y libmemcached libmemcached-devel
# RUN wget -O $SRC_DIR/memcached-3.0.3.tgz https://pecl.php.net/get/memcached-3.0.3.tgz \
#     && tar xzf $SRC_DIR/memcached-3.0.3.tgz -C $SRC_DIR \
#     && cd $SRC_DIR/memcached-3.0.3 \
#     && $PHP_PREFIX/bin/phpize \
#     && ./configure --with-php-config=$PHP_PREFIX/bin/php-config --with-libmemcached-dir=/usr/local/libmemcached/ --disable-memcached-sasl \
#     && make \
#     && make install \
#     && echo "extension=memcached.so" > $PHP_CONFIG_FILE_PATH/php.d/memcached.ini

# RUN php -v && php -m | sort

# enable opcache
RUN sed 's|;opcache.enable|opcache.enable|' -i $PHP_CONFIG_FILE_PATH/php.ini \
    && echo 'zend_extension=opcache.so' > $PHP_CONFIG_FILE_PATH/php.d/opcache.ini 

RUN [ "$HTTPD_PREFIX" != "/usr" ] && ln -s $HTTPD_PREFIX/bin/httpd /usr/sbin/httpd && mkdir -p /var/www &&  ln -s $HTTPD_PREFIX/htdocs /var/www/html; \
    [ "$PHP_PREFIX" != "/usr" ] && ln -s $PHP_PREFIX/bin/php /usr/bin/php 

RUN rm -f /var/www/html/index.html \
    && echo '<?php phpinfo();' > /var/www/html/index.php \
    && echo '# Enable php7 to deal .php files.'  > $HTTPD_PREFIX/conf/extra/php.conf \
    && echo 'AddHandler php7-script .php'       >> $HTTPD_PREFIX/conf/extra/php.conf \
    && echo 'AddType text/html .php'            >> $HTTPD_PREFIX/conf/extra/php.conf \
    && echo 'DirectoryIndex index.php'          >> $HTTPD_PREFIX/conf/extra/php.conf \
    && echo 'Include conf/extra/php.conf'   >> $HTTPD_PREFIX/conf/httpd.conf \
    && sed 's|logs/access_log|/dev/stdout|' -i $HTTPD_PREFIX/conf/httpd.conf \
    && sed 's|logs/error_log|/dev/stderr|'  -i $HTTPD_PREFIX/conf/httpd.conf \
    && yum clean all 

# Test Apache version
RUN httpd -v

# test php version
RUN php -v && php -m | sort

EXPOSE 80 443

CMD [ "/usr/sbin/httpd", "-DFOREGROUND" ]
