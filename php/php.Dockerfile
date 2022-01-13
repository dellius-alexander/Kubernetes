ARG buildno
ARG gitcommithash
#################################################
# FIRST BUILD STAGE
FROM php:7.4.18-apache as setup_ext
RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"
## Docker PHP Extension Installer
# https://github.com/mlocati/docker-php-extension-installer
## Download the "install-php-extensions" script
# ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
COPY --from=mlocati/php-extension-installer:1.2.24 /usr/bin/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync
#################################################
# EXTENSIONS INSTALLATION
RUN /usr/local/bin/install-php-extensions \
bcmath \
bz2 \
curl \
calendar \
decimal \
ffi \
ftp \
fileinfo \
gettext \
gmp \
intl \
imap \
json \
ldap \
mbstring \
exif \
memcached \
mysqli \
oauth \
odbc \
opcache \
openssl \
PDO \
pdo_mysql \
pdo_odbc \
pdo_pgsql \
pdo_sqlite \
pgsql \
redis \
shmop \
soap \
sockets \
sodium \
sqlite3 \
ssh2 \
tensor \
tidy \
xdebug
#################################################
# Clean up after install
RUN apt-get update -y && \
apt-get install -y sendmail && \
apt-get clean && \
apt-get autoremove
#################################################
# SECOND BUILD STAGE
FROM setup_ext as setup_env
#################################################
# ENVIRONMENTAL VARIABLES
ENV APACHE_RUN_DIR=/var/www/html
ENV APACHE_LOG_DIR=/var/log
ENV PHP_LOG_DIR=/var/log
RUN php -v && php -m
#################################################
FROM setup_env
RUN apt-get update && \
apt-get install -y unzip \
zip
RUN mkdir -p /var/www/html/composer
COPY install_composer.sh /var/www/html/composer/
RUN cd /var/www/html/composer && \
chmod a+x install_composer.sh && \
./install_composer.sh
RUN composer require monolog/monolog
RUN ls -lia /var/www/html/*