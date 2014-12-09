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
  apt-get install -y git pkg-config bsdmainutils build-essential libtool autotools-dev autoconf libssl-dev libboost-all-dev libdb4.8-dev libdb4.8++-dev; \
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
RUN make

# Phew.. Ok, so now we have built Mastercoin and surprise surprise, we now need to 
# download a FREAKING TORRENT CLIENT so that we can download the ENTIRE Bitcoin Blockchain. 
# I could have done this up above but it's not really a dependency now, is it? Keeping it tidy..
RUN apt-get install transmission-cli

# But wait.. transmission-cli doesn't just "stop" after it's done downloading. Fuuuuu.. WHAT DO?
# We have to create a freaking script that transmission-cli runs after it's downloaded the blockchain..
# If you were doing this manually you'd just hit ctrl-c, but nooooo.. Automated installation means it's a PITA
# Anyways, here's the solution. You're welcome. This only wasted 2 hours of my life..
RUN printf "#\041/bin/bash\npkill -9 transmission\n" >> /killme_already.sh
RUN chmod +x /killme_already.sh

# Now we will download the Blockchain. Uggggg.. Seriously, someone just shoot me. Do it..
# You're going to need ~20gb free because bitcoin just loooooves it some bloat..
# Maybe it's time to figure out a better solution like, oh.. pruning the blockchain?
# At least we could truncate the blockchain and start at a block just before mastercoin going live????? RIGHT? God.
# Whatever. Here we go. This downloads the blockchain into the bitcoin data directory
# After the blockchain is downloaded, transmission-cli runs the killme_already.sh script to end the process..
# RUN transmission-cli -w ~/.bitcoin -f /killme_already.sh https://bitcoin.org/bin/blockchain/bootstrap.dat.torrent
RUN transmission-cli -w ~/.bitcoin -f /killme_already.sh http://torcache.net/torrent/55282A6D8AA608CAED27B0250605AAE6E0EE2F4F.torrent

# Ok, so we've downloaded the blockchain. Now we remove the unholy and unnecessary remnants of that nonsense..
RUN rm /killme_already.sh
RUN apt-get remove transmission-cli
