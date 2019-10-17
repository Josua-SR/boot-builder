## i.MX8M Mini U-Boot Builder

## Description
This software uses docker to create a consistent build environment for compiling U-Boot images from source code for i.MX8M Mini based devices.

## Install
From a clone of **this** repository:

    docker build -t imx8mmubbldr docker

## Usage
### Fetch sources
    docker run -v "$PWD:/work" imx8mmubbldr -u $(id -u) -g $(id -g) -- init
    docker run -v "$PWD:/work" imx8mmubbldr -u $(id -u) -g $(id -g) -- sync
    docker run -v "$PWD:/work" imx8mmubbldr -u $(id -u) -g $(id -g) -- blobs

### Build U-Boot
    docker run -v "$PWD:/work" imx8mmubbldr -u $(id -u) -g $(id -g) -- build <options>

Options:
- -d,--device:  Device to build for (default: 'mcbin')
- -b,--boot:  Boot media to build for (default: 'microsd')

Examples:
- Hummingboard Pulse, microSD:

      docker run -v "$PWD:/work" imx8mmubbldr -u $(id -u) -g $(id -g) -- build -d hbp -b microsd
