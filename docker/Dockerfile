FROM debian:buster

# update
RUN set -e; \
	apt-get update; \
	apt-get -y upgrade; \
	apt-get clean; \
	:

# install tools
RUN apt-get -y install dosfstools mtools qemu-utils u-boot-tools

# prepare entrypoint
VOLUME /work
WORKDIR /app
ADD shflags /app/
ADD uenv.conf /app/
ADD entry.sh /app/
ENTRYPOINT ["/bin/bash", "/app/entry.sh"]
