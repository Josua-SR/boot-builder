## i.MX8M Q U-Boot Builder

## Description
This software uses docker to create a consistent build environment for compiling U-Boot images from source code for i.MX8M Q based devices.

## Install
From a clone of **this** repository:

    docker build -t imx8mqubbldr docker

From our container registry:

    docker pull container.solid-build.xyz/bsp/imx8mq-uboot-builder
    docker tag container.solid-build.xyz/bsp/imx8mq-uboot-builder imx8mqubbldr

## Usage
### Fetch sources
    docker run -v "$PWD:/work" imx8mqubbldr -u $(id -u) -g $(id -g) -- init
    docker run -v "$PWD:/work" imx8mqubbldr -u $(id -u) -g $(id -g) -- sync
    docker run -v "$PWD:/work" imx8mqubbldr -u $(id -u) -g $(id -g) -- blobs

### Build U-Boot
    docker run -v "$PWD:/work" imx8mqubbldr -u $(id -u) -g $(id -g) -- build <options>

Options:
- -d,--device:  Device to build for
- -b,--boot:  Boot media to build for

Examples:
- CuBox Pulse, microSD:

      docker run -v "$PWD:/work" imx8mqubbldr -u $(id -u) -g $(id -g) -- build -d imx8mq-cubox-pulse -b microsd

- Hummingboard Pulse, microSD:

      docker run -v "$PWD:/work" imx8mqubbldr -u $(id -u) -g $(id -g) -- build -d imx8mq-hummingboard-pulse -b microsd

### Customize where source code is pulled from

The default manifest used by the repo command can be overriden by customizing the provided *local.xml* and placing it in the working directory.

The next `sync` step will pull in the file, indicated by the message *"Applying overrides from local.xml!"*.
