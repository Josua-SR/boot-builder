FROM debian:buster

# configure apt
ADD sources.list /etc/apt/sources.list

# apt proxy (optional)
ARG APTPROXY=
RUN test -n "$APTPROXY" && printf 'Acquire::http { Proxy "%s"; }\n' $APTPROXY | tee -a /etc/apt/apt.conf.d/proxy || true

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
RUN apt-get -y install bc bison device-tree-compiler flex git libssl-dev sudo wget zlib1g-dev
RUN apt-get -y -t buster-backports install repo

# configure entrypoint
ADD shflags /shflags
ADD entry.sh /entry.sh
ADD main.sh /main.sh
RUN chmod 755 /entry.sh /main.sh
WORKDIR /work
ENTRYPOINT ["/bin/bash", "/entry.sh"]
