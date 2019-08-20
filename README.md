## Armada 8040 U-Boot Installer Builder

## Description
This software uses docker to create a consistent build environment for creating bootable installer images from U-Boot binaries for Armada 8040 based devices.

## Install
From a clone of **this** repository:

    docker build -t 8040ubinstbldr docker

## Usage
Inside a clone of **this** repository:

    cp /some/place/u-boot-cfgt-{emmc_data,microsd,spi}.bin ./
    docker run -v "$PWD:/work" 8040ubinstbldr -u $(id -u) -g $(id -g)

As a result **u-boot-installer-cfgt-microsd.img** is created in the current directory.

### Examples:
- MacchiatoBIN, generic block image (for USB, SATA, mmc)

    docker run -v "$PWD:/work" 8040ubinstbldr -u $(id -u) -g $(id -g) -d mcbin -b generic

- Clearfog GT, microSD image with u-boot embedded

    docker run -v "$PWD:/work" 8040ubinstbldr -u $(id -u) -g $(id -g) -d cfgt -b microsd
