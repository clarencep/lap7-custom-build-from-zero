#!/bin/sh -xe

IMAGE_NAME=lap7-custom-build-from-zero:centos6

docker build -t clarencep/$IMAGE_NAME .

cat ./check-extensions.php | docker run -i --rm clarencep/$IMAGE_NAME php

docker run --rm clarencep/$IMAGE_NAME sh -c '\
    echo ""; \
    echo OS Version; \
    echo --------------; \
    cat /etc/*release;\
    echo ""; \
    echo PHP Version; \
    echo --------------; \
    php -v; \
    echo ""; \
    echo PHP Modules; \
    echo --------------; \
    php -m;' > versions.txt

docker run --rm clarencep/$IMAGE_NAME php -i > phpinfo.txt


