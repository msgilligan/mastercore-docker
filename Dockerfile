# This Dockerfile does a few things
# 1. Makes Ubuntu sound for building and running daemons from source in a Docker container (credit: phusion @ github)
# 2. Adds the Mastercoin & Bitcoin required Repos and uses apt-get to install dependencies
# 3. Automates the headless Mastercoin build process
# 4. Creates cronjobs that fail and restart elegantly

# Here we pick the base image we are going to use to install Mastercoin on and issue commands for phusion scripts to make Ubuntu sane for Docker
FROM ubuntu:14.04
MAINTAINER phusion@github

ENV HOME /root
RUN mkdir /build
ADD . /build

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

CMD ["/sbin/my_init"]

# Now we install build dependencies listed  (from: mscore-0.0.8/doc/build-unix.md)
RUN { \
  apt-get update; \
  apt-get install software-properties-common; \
  add-apt-repository ppa:bitcoin/bitcoin; \
  apt-get update; \
  apt-get install -y git pkg-config build-essential libtool autotools-dev autoconf libssl-dev libboost-all-dev libdb4.8-dev libdb4.8++-dev; \
}

# Now we clean up APT temporary files because cleanliness is next to Bitcoininess (sp?)
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Now let's go ahead and use git to clone the Mastercoin repo over at Github (from: mscore-0.0.8/README.md)
RUN git clone https://github.com/mastercoin-MSC/mastercore.git

# Ok great, we've downloaded the most recent version of Mastercoin from Github. Now what? Oh.. Right..
RUN ./autogen.sh
RUN ./configure
RUN make
