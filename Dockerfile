FROM php:8.3-cli

# System libs + build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
        libaio1t64 unzip curl git libzip-dev libonig-dev libxml2-dev $PHPIZE_DEPS \
    && ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1 \
    && rm -rf /var/lib/apt/lists/*

# Oracle Instant Client (Basic + SDK, latest) and PHP oci8 extension
ENV ORACLE_HOME=/opt/oracle/instantclient
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient
RUN mkdir -p /opt/oracle && cd /opt/oracle \
    && curl -fsSLO https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip \
    && curl -fsSLO https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip \
    && unzip -qo instantclient-basic-linuxx64.zip && unzip -qo instantclient-sdk-linuxx64.zip \
    && rm -f *.zip \
    && mv instantclient_* instantclient \
    && echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf && ldconfig \
    && docker-php-ext-install pdo mbstring zip bcmath pcntl \
    && echo "instantclient,/opt/oracle/instantclient" | pecl install oci8-3.4.0 \
    && docker-php-ext-enable oci8

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
