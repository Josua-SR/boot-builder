## Armada 8040 U-Boot Builder

## Description
This software uses docker to create a consistent build environment for compiling U-Boot images from source code for Armada 8040 based devices.

## Install
From a clone of **this** repository:

    docker build -t 8040ubbldr docker

## Usage
### Fetch sources
    docker run -v "$PWD:/work" 8040ubbldr -u $(id -u) -g $(id -g) -- init
    docker run -v "$PWD:/work" 8040ubbldr -u $(id -u) -g $(id -g) -- sync

### Build U-Boot
    docker run -v "$PWD:/work" 8040ubbldr -u $(id -u) -g $(id -g) -- build <options>

Options:
- -d,--device:  Device to build for (default: 'mcbin')
- -b,--boot:  Boot media to build for (default: 'microsd')

Examples:
- Clearfog GT, SPI Flash:

      docker run -v "$PWD:/work" 8040ubbldr -u $(id -u) -g $(id -g) -- build -d cfgt -b spi

- MacchiatoBIN, eMMC boot1:

      docker run -v "$PWD:/work" 8040ubbldr -u $(id -u) -g $(id -g) -- build -d mcbin -b emmc_boot1
