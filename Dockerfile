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
  apt-get install -y git wget pkg-config bsdmainutils build-essential libtool 
  autotools-dev autoconf libssl-dev libboost-all-dev libdb4.8-dev libdb4.8++-dev; \
}

# Now we clean up APT temporary files because cleanliness is next to Bitcoininess (sp?)
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Now let's go ahead and use git to clone the Mastercoin repo over at Github (from: mscore-0.0.8/README.md)
# Once cloned from the Mastercoin repo, the files will be in the ~/Mastercore directory or something..
RUN git clone https://github.com/mastercoin-MSC/mastercore.git

# Ok great, we've downloaded the most recent version of Mastercoin from Github. Still stuff to do.. Hmm..
# Now what? Oh.. Right.. Let's build it! BUILDDDDD ITTTTTT! READY, GO.
RUN ./mastercore/autogen.sh
RUN ./mastercore/configure
RUN ./mastercore/make

# Phew.. Ok, so now we have built Mastercoin and surprise surprise, we now need to 
# download a FREAKING TORRENT CLIENT so that we can download the ENTIRE Bitcoin Blockchain. 
# Why? BECAUSE BITCOIN.
RUN apt-get install transmission-cli

# Got the Torrent client installed? Niceeeeeee. Now we have to download the Blockchain.  
# We're going to grab the magnet link signed by the Famous Jeff Garzik (http://gtf.org/garzik/bitcoin/bootstrap.txt)
RUN wget http://gtf.org/garzik/bitcoin/bootstrap.txt

https://bitcoin.org/bin/blockchain/bootstrap.dat.torrent
