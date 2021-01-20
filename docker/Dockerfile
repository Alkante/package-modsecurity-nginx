# Dockerfile
FROM debian:buster
ENV DEBIAN_FRONTEND noninteractive

ARG USER_ID
ARG GROUP_ID

RUN apt-get update && apt-get upgrade -y && apt-get install -y git g++ flex bison curl doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev libssl-dev zlib1g-dev libxslt-dev libgd-dev wget dpkg-sig sudo

RUN groupadd -g ${GROUP_ID} maker && useradd -l -u ${USER_ID} -g maker maker
RUN usermod -aG sudo maker
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER maker