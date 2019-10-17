FROM debian:stretch

# configure apt
ADD sources.list /etc/apt/sources.list

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
RUN apt-get -y install bc bison device-tree-compiler flex libssl-dev repo sudo wget zlib1g-dev

# configure entrypoint
ADD shflags /shflags
ADD entry.sh /entry.sh
ADD main.sh /main.sh
WORKDIR /work
ENTRYPOINT ["/bin/bash", "/entry.sh"]
