## Armada 8040 U-Boot Builder

## Description
This software uses docker to create a consistent build environment for compiling U-Boot images from source code for Armada 8040 based devices.

## Install
From a clone of **this** repository:

    docker build -t imx8ubbldr docker

## Usage
### Fetch sources
    docker run -v "$PWD:/work" imx8ubbldr -u $(id -u) -g $(id -g) -- init
    docker run -v "$PWD:/work" imx8ubbldr -u $(id -u) -g $(id -g) -- sync
    docker run -v "$PWD:/work" imx8ubbldr -u $(id -u) -g $(id -g) -- blobs

### Build U-Boot
    docker run -v "$PWD:/work" imx8ubbldr -u $(id -u) -g $(id -g) -- build <options>

Options:
- -d,--device:  Device to build for (default: 'mcbin')
- -b,--boot:  Boot media to build for (default: 'microsd')

Examples:
- Hummingboard Pulse, microSD:

      docker run -v "$PWD:/work" imx8ubbldr -u $(id -u) -g $(id -g) -- build -d hbp -b microsd
