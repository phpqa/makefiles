FROM php:8.1-fpm-buster as base
RUN apt-get --quiet update \
    && apt-get --quiet install --yes autoconf g++ make git zip \
    && rm -rf /var/lib/apt/lists/* && apt-get clean
WORKDIR /app
COPY ./docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV PATH="$PATH:/app/bin"
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "php-fpm" ]
