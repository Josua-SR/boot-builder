## Armada 8040 UEFI Builder

## Description
This software uses docker to create a consistent build environment for compiling UEFI images from source code for Armada 8040 based devices.

## Install
From a clone of **this** repository:

    docker build -t 8040efibldr docker

## Usage
### Fetch sources
    docker run -v "$PWD:/work" 8040efibldr -u $(id -u) -g $(id -g) -- init
    docker run -itv "$PWD:/work" 8040efibldr -u $(id -u) -g $(id -g) -- sync

### Build UEFI
    docker run -itv "$PWD:/work" 8040efibldr -u $(id -u) -g $(id -g) -- build <options>

Options:
- -d,--device:  Device to build for (default: 'mcbin')
- -b,--boot:  Boot media to build for (default: 'spi')

Examples:
- MacchiatoBIN, SPI Flash:

      docker run -itv "$PWD:/work" 8040efibldr -u $(id -u) -g $(id -g) -- build -d mcbin -b spi

## Customize

- default.xml: Defines source code versions for the repo tool to fetch. Changes require a new commit to be made, **before** rerunning the sync step.
- build.sh: Controls the complete build process. Changes to build steps can be made here and are picked immediately without rebuilding the container.
