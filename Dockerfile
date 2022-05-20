FROM ubuntu:18.04

LABEL maintainer="narbone@adobe.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ondrej/php

RUN apt-get install -y \
    apt-utils \
    ssh \
    curl \
    git \
    php7.4-cli \
    php7.4-bcmath \
    php7.4-curl \
    php7.4-fpm \
    php7.4-gd \
    php7.4-mbstring \
    php7.4-mysql \
    php7.4-soap \
    php7.4-xml \
    php7.4-zip \
    php7.4-intl \
    vim \
    nano \
    unzip \
    nginx \
    mariadb-server \
    mariadb-client \
    net-tools \
    locales \
    ca-certificates 

# install mariadb 10.4
RUN apt-get remove -y mariadb-server
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.lstn.net/mariadb/repo/10.4/ubuntu bionic main'
RUN apt-get update -y
RUN apt-get install -y mariadb-server

# clenup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# set locales
RUN locale-gen en_AU.UTF-8

# nginx default file
COPY default /etc/nginx/sites-available/

# ssl certificates
COPY magento2.local.crt /etc/nginx/magento2.local.crt
COPY magento2.local.key /etc/nginx/magento2.local.key

# extend php-fpm memory limit
RUN echo 'memory_limit = 2G' >> /etc/php/7.4/fpm/php.ini

# install composer 2
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


# expose ports
EXPOSE 80
EXPOSE 443
EXPOSE 3306

# create ubuntu user, add it to ngnix group and vice versa
RUN useradd -ms /bin/bash ubuntu
RUN usermod -a -G www-data ubuntu
RUN usermod -a -G ubuntu www-data

# install Magento CLI and get host ssh keys to clone Magento cloud repos later
USER ubuntu
WORKDIR /home/ubuntu
RUN curl -sS https://accounts.magento.cloud/cli/installer | php
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY
RUN mkdir -p /home/ubuntu/.ssh
RUN echo "${SSH_PRIVATE_KEY}" > /home/ubuntu/.ssh/id_rsa
RUN echo "${SSH_PUBLIC_KEY}" > /home/ubuntu/.ssh/id_rsa.pub
RUN chmod 600 /home/ubuntu/.ssh/id_rsa
RUN chmod 644 /home/ubuntu/.ssh/id_rsa.pub

# finally start the container as root
USER root
