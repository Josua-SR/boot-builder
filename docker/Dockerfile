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
RUN apt-get -y install bc bison flex git libssl-dev repo sudo wget

# create git repository with default.xml
WORKDIR /manifest
RUN set -e; git init .; git config --local user.name "SolidRun Ltd."; git config --local user.email "support@solid-run.com"; :
ADD default.xml /manifest/
RUN set -e; git add default.xml; git commit -m 'Initial Commit'; :

# configure entrypoint
ADD shflags /shflags
ADD entry.sh /entry.sh
ADD main.sh /main.sh
RUN chmod 755 /entry.sh /main.sh
WORKDIR /work
ENTRYPOINT ["/bin/bash", "/entry.sh"]
