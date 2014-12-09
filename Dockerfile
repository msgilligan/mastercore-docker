# TO BUILD: $ docker build -t mastercore github.com/squarestreamio/mastercore-docker.git
# This Dockerfile does a few things
# 1. Makes Ubuntu sound for building and running nonsense from source in a Docker container
# 2. Adds the Mastercoin & Bitcoin required Repos and uses apt-get to install dependencies
# 3. Automates the headless Mastercoin build process
# 4. Creates a termination script for transmission-cli once it's done downloading the blockchain
# 5. Installs transmission-cli, downloads the blockchain via torrent
# 6. Removes termination script & issues apt-get remove transmission-cli to clean up
# 7. Change RPC server command from #server=0 to server=1
# 8. Run bitcoind getinfo. Output sent to file bitcoind_getinfo.result
# 9. [TODO] Add cron jobs and nonsense like that..

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
  apt-get install libssl-dev; \
  apt-get install libdb4.8; \
  apt-get libboost-all-dev; \
  apt-get libminiupnpc-dev; \
  apt-get libqtgui4; \ 
  apt-get libprotobuf8; \
  apt-get libqrencode3; \
  apt-get git; \
  apt-get pkg-config; \
  apt-get bsdmainutils; \
  apt-get build-essential; \
  apt-get libtool; \
  apt-get autotools-dev; \
  apt-get autoconf ; \
}

# Now we clean up APT temporary files because cleanliness is next to Bitcoininess (sp?)
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Now let's go ahead and use git to clone the Mastercoin repo over at Github (from: mscore-0.0.8/README.md)
# Once cloned from the Mastercoin repo, the files will be in the ~/Mastercore directory or something..
RUN git clone https://github.com/mastercoin-MSC/mastercore.git

# Ok great, we've downloaded the most recent version of Mastercoin from Github. Still stuff to do.. Hmm..
# Now what? Oh.. Right.. Let's build it! BUILDDDDD ITTTTTT! READY, GO.
RUN mastercore/autogen.sh
RUN mastercore/configure
RUN cd mastercore/
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
# This is the real torrent -> RUN transmission-cli -w ~/.bitcoin -f /killme_already.sh https://bitcoin.org/bin/blockchain/bootstrap.dat.torrent
# I'm using the one below for testing b/c it's not 20GB.. 
RUN transmission-cli -w ~/.bitcoin -f /killme_already.sh http://torcache.net/torrent/55282A6D8AA608CAED27B0250605AAE6E0EE2F4F.torrent

# Ok, so we've downloaded the blockchain. Now we remove the unholy and unnecessary remnants of that nonsense..
RUN rm /killme_already.sh
RUN apt-get remove transmission-cli

# Ok, whatever. It's 2:50am. Now we're going to make it possible to issue RPC commands using 'sed' Whoopeeee!!
# 
RUN sed -i .bak 's/#server=0/server=1/' ~/.bitcoin/bitcoin.conf

# That didn't take too long. We're getting the hang of this! Now we're going to see if the previous
# step actually worked. Additionally, because I just figured out how to do it, we're going 
# to save the output to a file called bitcoind_getinfo.result because why not? I mean, 
RUN cd src/
RUN ./bitcoind getinfo > bitcoind_getinfo.result

# Now we start Mastercore ./bitcoind. A first time run will take approximately 10-15 minutes
RUN cd src/
RUN ./bitcoind
