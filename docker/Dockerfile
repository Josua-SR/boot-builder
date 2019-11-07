FROM debian:buster

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

# install build dependencies
RUN apt-get -y install acpica-tools device-tree-compiler uuid-dev
RUN apt-get -y install libssl-dev

# install tools
RUN apt-get -y install repo sudo

# configure entrypoint
ADD shflags /shflags
ADD entry.sh /entry.sh
ADD main.sh /main.sh
WORKDIR /work
ENTRYPOINT ["/bin/bash", "/entry.sh"]
