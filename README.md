## CN913x U-Boot Builder

## Description
This software uses docker to create a consistent build environment for compiling U-Boot images from source code for CN913x based devices.

## Install
From a clone of **this** repository:

    docker build -t cn913ubbldr docker

## Usage
### Fetch sources
    docker run -v "$PWD:/work" cn913ubbldr -u $(id -u) -g $(id -g) -- init
    docker run -v "$PWD:/work" cn913ubbldr -u $(id -u) -g $(id -g) -- sync

### Build U-Boot
    docker run -v "$PWD:/work" cn913ubbldr -u $(id -u) -g $(id -g) -- build <options>

Options:
- -d,--device:  Device to build for (default: 'cfbase-9130')
- -b,--boot:  Boot media to build for (default: 'microsd')

Examples:
- Clearfog Base, SPI Flash:

      docker run -v "$PWD:/work" cn913ubbldr -u $(id -u) -g $(id -g) -- build -d cfbase-9130 -b spi

- Clearfog Pro, eMMC boot1:

      docker run -v "$PWD:/work" cn913ubbldr -u $(id -u) -g $(id -g) -- build -d cfpro-9130 -b emmc_boot1
