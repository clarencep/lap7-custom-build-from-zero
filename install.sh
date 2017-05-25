#!/bin/sh -xe

PHP_VERSION=7.1.5
HTTPD_VERSION=2.4.25

LIBICONV_VERSION=1.15
APR_VERSION=1.5.2
APR_UTIL_VERSION=1.5.4
APR_ICONV_VERSION=1.2.1

SRC_DIR=/data/server/src
HTTPD_PREFIX=/data/server/httpd-$HTTPD_VERSION

CFLAGS='-O3'

PHP_PREFIX=/data/server/php-$PHP_VERSION
PHP_CONFIG_FILE_PATH=$PHP_PREFIX/etc
PECL=$PHP_PREFIX/bin/pecl

yum install -y wget gcc gcc-c++  make automake autoconf

# download sources
mkdir -p $SRC_DIR 

wget -O $SRC_DIR/php-$PHP_VERSION.tar.gz http://cn2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror 
tar -xzf $SRC_DIR/php-$PHP_VERSION.tar.gz -C $SRC_DIR 
rm -f $SRC_DIR/php-$PHP_VERSION.tar.gz 

wget -O $SRC_DIR/libiconv-$LIBICONV_VERSION.tar.gz http://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz 
tar -xzf $SRC_DIR/libiconv-$LIBICONV_VERSION.tar.gz -C $SRC_DIR 
rm -f $SRC_DIR/libiconv-$LIBICONV_VERSION.tar.gz 

wget -O $SRC_DIR/httpd-$HTTPD_VERSION.tar.gz http://mirror.bit.edu.cn/apache//httpd/httpd-$HTTPD_VERSION.tar.gz 
tar -xzf $SRC_DIR/httpd-$HTTPD_VERSION.tar.gz -C $SRC_DIR 
rm -f $SRC_DIR/httpd-$HTTPD_VERSION.tar.gz 

wget -O $SRC_DIR/apr-$APR_VERSION.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache//apr/apr-$APR_VERSION.tar.gz 
tar -xzf $SRC_DIR/apr-$APR_VERSION.tar.gz -C $SRC_DIR 
rm -f $SRC_DIR/apr-$APR_VERSION.tar.gz 
    
wget -O $SRC_DIR/apr-util-$APR_UTIL_VERSION.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache//apr/apr-util-$APR_UTIL_VERSION.tar.gz 
tar -xzf $SRC_DIR/apr-util-$APR_UTIL_VERSION.tar.gz -C $SRC_DIR 
rm -f $SRC_DIR/apr-util-$APR_UTIL_VERSION.tar.gz 
    
wget -O $SRC_DIR/apr-iconv-$APR_ICONV_VERSION.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache//apr/apr-iconv-$APR_ICONV_VERSION.tar.gz 
tar -xzf $SRC_DIR/apr-iconv-$APR_ICONV_VERSION.tar.gz -C $SRC_DIR 
rm -f $SRC_DIR/apr-iconv-$APR_ICONV_VERSION.tar.gz 
     
# install dependencies
yum install -y libxml2 libxml2-devel gmp-devel \
                libzip-devel zlib-devel bzip2-devel \
                gettext-devel libcurl-devel gd-devel openssl-devel \
                readline readline-devel libxslt libxslt-devel \
                recode recode-devel \
                sqlite sqlite-devel \
                pcre pcre-devel \
                libicu libicu-devel \
                ImageMagick ImageMagick-devel \
                libtool 

# compile and install libiconv
cd $SRC_DIR/libiconv-$LIBICONV_VERSION 
./configure --prefix=/usr/local/libiconv  
make && make install 
libtool --finish /usr/local/libiconv/lib 
ls -al /usr/local/libiconv 
     
# compile and install apr
cd $SRC_DIR/apr-$APR_VERSION 
./configure --prefix=$HTTPD_PREFIX/apr 
make 
mkdir -p $HTTPD_PREFIX $HTTPD_PREFIX/apr 
make install 
    
cd $SRC_DIR/apr-util-$APR_UTIL_VERSION 
./configure --prefix=$HTTPD_PREFIX/apr-util --with-apr=$HTTPD_PREFIX/apr 
make 
mkdir -p $HTTPD_PREFIX $HTTPD_PREFIX/apr-util 
make install 
     
cd $SRC_DIR/apr-iconv-1.2.1 
./configure --prefix=$HTTPD_PREFIX/apr-iconv --with-apr=$HTTPD_PREFIX/apr
make 
mkdir -p $HTTPD_PREFIX $HTTPD_PREFIX/apr-iconv 
make install 
 
# compile and install HTTPD
cd $SRC_DIR/httpd-$HTTPD_VERSION 
./configure \
    --prefix=$HTTPD_PREFIX \
    --with-apr=$HTTPD_PREFIX/apr \
    --with-apr-util=$HTTPD_PREFIX/apr-util \
    --enable-mods-shared=all 
        #   --enable-rewrite 
        #   --enable-proxy 
        #   --enable-proxy-http 
        #   --enable-ssl 
        #   --enable-http2 
        #   --enable-proxy-http2 
make 
make install 


# install mcrypt and mhash
{
    OS_VERSION="x"`cat /etc/os-release  | grep VERSION_ID | grep -o -E '[0-9]+'  || echo 6`
    if [ "$OS_VERSION" == "x7" ]; then
        wget -O $SRC_DIR/epel-release-7-9.noarch.rpm http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
        wget -O $SRC_DIR/remi-release-7.rpm http://rpms.famillecollet.com/enterprise/remi-release-7.rpm 
        rpm -Uvh $SRC_DIR/remi-release-7*.rpm $SRC_DIR/epel-release-7*.rpm 
        yum install -y libmcrypt-devel 
        yum install -y libmhash-devel 
        rm -f $SRC_DIR/remi-release-7*.rpm $SRC_DIR/epel-release-7*.rpm 
    fi;
    if [ "$OS_VERSION" == "x6" ]; then
        wget -O $SRC_DIR/epel-release-6-8.noarch.rpm http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm 
        wget -O $SRC_DIR/remi-release-6.rpm http://rpms.famillecollet.com/enterprise/remi-release-6.rpm 
        rpm -Uvh $SRC_DIR/remi-release-6*.rpm $SRC_DIR/epel-release-6*.rpm 
        yum install -y libmcrypt-devel 
        yum install -y libmhash-devel 
        rm -f $SRC_DIR/remi-release-6*.rpm $SRC_DIR/epel-release-6*.rpm 
    fi;
}

# compile and install php
cd $SRC_DIR/php-$PHP_VERSION 
./configure \
        --prefix=$PHP_PREFIX \
        --with-config-file-path=$PHP_CONFIG_FILE_PATH \
        --with-config-file-scan-dir=$PHP_CONFIG_FILE_PATH/php.d \
        --with-apxs2=$HTTPD_PREFIX/bin/apxs \
        --disable-debug \
        --disable-phpdbg \
        --with-pic \
        --disable-rpath \
        --with-freetype-dir=/usr \
        --with-png-dir=/usr \
        --with-xpm-dir=/usr \
        --enable-gd-native-ttf \
        --with-t1lib=/usr \
        --without-gdbm \
        --with-jpeg-dir=/usr \
        --with-openssl \
        --with-pcre-regex \
        --with-zlib \
        --with-layout=GNU \
        --with-kerberos \
        --with-libxml-dir=/usr \
        --with-system-tzdata \
        --with-mhash \
        --enable-force-cgi-redirect \
        --enable-pcntl \
        --enable-fastcgi \
        --enable-mbstring=shared \
        --enable-mbregex \
        --with-gd=shared \
        --with-gmp=shared \
        --enable-calendar=shared \
        --enable-bcmath=shared \
        --with-bz2=shared \
        --enable-ctype=shared \
        --enable-dba=shared \
        --enable-exif=shared \
        --enable-ftp=shared \
        --with-gettext=shared \
        --with-iconv=shared \
        --enable-sockets=shared \
        --enable-tokenizer=shared \
        --with-xmlrpc=shared \
        --enable-dom=shared \
        --enable-simplexml=shared \
        --enable-xml=shared \
        --enable-wddx=shared \
        --enable-soap=shared \
        --with-xsl=shared,/usr \
        --enable-xmlreader=shared \
        --enable-xmlwriter=shared \
        --with-curl=shared,/usr \
        --enable-mysqlnd=shared \
        --with-mysqli=shared,mysqlnd \
        --with-mysql-sock=/var/lib/mysql/mysql.sock \
        --enable-pdo=shared \
        --with-pdo-mysql=shared,mysqlnd \
        --with-pdo-sqlite=shared,/usr \
        --with-sqlite3=shared,/usr \
        --enable-json=shared \
        --enable-zip=shared \
        --enable-phar=shared \
        --with-mcrypt=shared,/usr \
        --enable-sysvmsg=shared \
        --enable-sysvshm=shared \
        --enable-sysvsem=shared \
        --enable-shmop=shared \
        --enable-posix=shared \
        --enable-intl=shared \
        --with-recode=shared,/usr \
        --with-readline=shared \
        --enable-opcache 

# --with-libedit 
# --with-imap 
# --with-ldap 

make  
# make test 
make install 
     
     
# configure PHP 
mkdir -p $PHP_CONFIG_FILE_PATH/php.d 
cp $SRC_DIR/php-$PHP_VERSION/php.ini-production $PHP_CONFIG_FILE_PATH/php.ini 

{
    cd `$PHP_PREFIX/bin/php-config --extension-dir` 

    # ensure mysqli loads after mysqlnd: 
    mv mysqli.so mysqlnd_mysqli.so  

    # enable all shared extensions: 
    for x in *.so; do 
        echo "extension=$x" > $PHP_CONFIG_FILE_PATH/php.d/${x/.so/}.ini; 
    done; 
}

# enable opcache 
rm -f $PHP_CONFIG_FILE_PATH/php.d/opcache.ini 
sed 's|;opcache.enable|opcache.enable|' -i $PHP_CONFIG_FILE_PATH/php.ini 
echo 'zend_extension=opcache.so' > $PHP_CONFIG_FILE_PATH/php.d/opcache.ini 

# fix pecl 
sed 's|PHP -C -n -q|PHP -C -q|' -i $PHP_PREFIX/bin/pecl
   
$PECL install redis     && echo "extension=redis.so" > $PHP_CONFIG_FILE_PATH/php.d/redis.ini 
$PECL install igbinary  && echo "extension=igbinary.so" > $PHP_CONFIG_FILE_PATH/php.d/igbinary.ini 
$PECL install inotify   && echo "extension=inotify.so" > $PHP_CONFIG_FILE_PATH/php.d/inotify.ini 
$PECL install imagick   && echo "extension=imagick.so" > $PHP_CONFIG_FILE_PATH/php.d/imagick.ini 

[ "$HTTPD_PREFIX" != "/usr" ] && ln -s $HTTPD_PREFIX/bin/httpd /usr/sbin/httpd && mkdir -p /var/www &&  ln -s $HTTPD_PREFIX/htdocs /var/www/html
[ "$PHP_PREFIX" != "/usr" ] && ln -s $PHP_PREFIX/bin/php /usr/bin/php
    
rm -f /var/www/html/index.html
echo '<?php phpinfo();' > /var/www/html/index.php
echo '# Enable php7 to deal .php files.'  > $HTTPD_PREFIX/conf/extra/php.conf
echo 'AddHandler php7-script .php'       >> $HTTPD_PREFIX/conf/extra/php.conf
echo 'AddType text/html .php'            >> $HTTPD_PREFIX/conf/extra/php.conf
echo 'DirectoryIndex index.php'          >> $HTTPD_PREFIX/conf/extra/php.conf
echo 'Include conf/extra/php.conf'   >> $HTTPD_PREFIX/conf/httpd.conf
sed 's|logs/access_log|/dev/stdout|' -i $HTTPD_PREFIX/conf/httpd.conf
sed 's|logs/error_log|/dev/stderr|'  -i $HTTPD_PREFIX/conf/httpd.conf

# cleanup 
yum clean all 
find /var/log/ -type f -print0 | xargs -0 rm -rf /tmp/*

# Test Apache version 
httpd -v 

# test php version 
php -v && php -m | sort
