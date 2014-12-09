# Dockerfile to automate building mastercore on ubuntu
FROM ubuntu:14.04
MAINTAINER squarestreamio

ENV HOME /root
RUN mkdir /build
ADD . /build

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

CMD ["/sbin/my_init"]

# Mastercore Build Instructions Go Here
RUN { \
  apt-get update; \
  add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu/ oldstable main" ; \
  apt-get update; \
  apt-get install python-software-properties; \
  add-apt-repository ppa:bitcoin/bitcoin; \
  apg-get update; \
  apt-get install -y git build-essential libtool autotools-dev autoconf libssl-dev libboost-all-dev libdb4.8-dev libdb4.8++-dev; \
}

# Let's clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
