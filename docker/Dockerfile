FROM debian:bullseye

# configure apt
ADD sources.list /etc/apt/sources.list

# optional apt-cacher-ng instance to cache package downloads
# RUN echo 'Acquire::http { Proxy "http://example.com:3142"; }' | tee -a /etc/apt/apt.conf.d/proxy

# update
RUN set -e; \
	apt-get update; \
	apt-get -y upgrade; \
	apt-get clean; \
	:

# install compiler
RUN set -e; \
	case $(dpkg --print-architecture) in \
		arm64) \
			apt-get -y install build-essential; \
			;; \
		*) \
			apt-get -y install crossbuild-essential-arm64; \
			;; \
	esac; \
	:

# install tools
RUN apt-get -y install bc bison flex libssl-dev libtinfo-dev repo sudo

# configure entrypoint
ADD shflags /shflags
ADD entry.sh /entry.sh
ADD main.sh /main.sh
WORKDIR /work
ENTRYPOINT ["/bin/bash", "/entry.sh"]
