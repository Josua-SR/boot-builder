#!/bin/bash
# 
# Copyright 2018-2019 Josua Mayer <josua@solid-run.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

# functions
do_init() {
	if [ -d build ]; then
		echo "Warning: 'build' directory exists already."
		echo "Not initializing!"
		return 1
	fi

	mkdir build
	pushd build
	repo init -u https://github.com/Josua-SR/boot-builder.git -b imx8-uboot -m manifest.xml $@
	status=$?
	popd

	if [ $status -ne 0 ];
		then rm -rf build;
	else
		echo "Initialzied source tree with default manifest. Overrides may be supplied through a local.xml file in the working directory."
	fi

	return $status
}

do_sync() {
	if [ ! -d build ]; then
		echo "Error: not initialized, run init first!"
		return 1
	fi

	localxml=local.xml
	if [ -e local.xml ]; then
		echo "Applying overrides from local.xml!"
		install -v -m644 -D local.xml build/.repo/local_manifests/local.xml
	else
		echo "Using default versions. Overrides may be supplied through a local.xml file in the working directory."
		rm -f build/.repo/local_manifests/local.xml
	fi

	pushd build
	repo sync $@
	status=$?
	popd

	return $status
}

do_blobs() {
	if [ -d blobs ]; then
		echo "Warning: 'blobs' directory exists already."
		echo "Not fetching!"
		return 1
	fi

	# declare version / chksum
	file=firmware-imx-8.10.bin
	dir=firmware-imx-8.10
	sha256sum=2b70f169d4065b2a7ac7a676afe24636128bd2dacc9f5230346758c3b146b2be

	# flags
	. /shflags
	DEFINE_boolean 'accept-eula' false "Accept NXP EULA for $file" 'a'
	FLAGS "$@" || exit 1
	eval set -- "${FLAGS_ARGV}"

	# fetch if necessary
	if [ ! -r "$file" ]; then
		wget -nc https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/$file
		status=$?
		if [ $status -ne 0 ]; then
			echo "Error: Can't download $file!"
			return $status
		fi
	fi

	# verify checksum
	echo $sha256sum $file | sha256sum -c
	status=$?
	if [ $status -ne 0 ]; then
		echo "Error: $file has wrong checksum, deleting!"
		echo "Retry or place the file matching sha256 $sha256sum in the working directory."
		rm -f $file
		return $status
	fi

	unpackacceptarg=
	# accept license?
	if [ ${FLAGS_accept_eula} -eq ${FLAGS_TRUE} ]; then
		unpackacceptarg=--auto-accept
	fi

	# unpack
	sh $file --force $unpackacceptarg
	status=$?

	if [ $status -ne 0 ]; then
		# unpacking is expected to fail if the license has not been accepted
		if [ ${FLAGS_accept_eula} -eq ${FLAGS_FALSE} ]; then
			echo "For accepting this EULA autoamtically, rerun with --accept-eula"
			return 1
		fi

		# failed for unknown reason
		return $status
	fi

	# copy required blobs
	mkdir blobs
	cp -v $dir/firmware/ddr/synopsys/lpddr4*.bin blobs/ || return 1
	cp -v $dir/firmware/hdmi/cadence/signed_hdmi_imx8m.bin blobs/ || return 1

	return 0
}

do_build() {
	if [ ! -d build ]; then
		echo "Error: not initialized, run init first!"
		return 1
	fi
	if [ ! -d build/u-boot_imx8mq ] || [ ! -d build/atf_imx8mq ]; then
		echo "Error: Sources not complete, run sync first!"
		return 1
	fi
	if [ ! -d blobs ]; then
		echo "Error: Binary blobs missing, run blobs first!"
		return 1
	fi

	# flags
	. /shflags
	DEFINE_string 'device' hbp 'Device to build for' 'd'
	DEFINE_string 'boot' microsd 'Boot media to build for' 'b'
	FLAGS "$@" || exit 1
	eval set -- "${FLAGS_ARGV}"

	# check arguments
	case ${FLAGS_device} in
		imx8mp-cubox-pulse)
			VARIANT=imx8mp
			DEVICE=cubox-pulse

			case ${FLAGS_boot} in
				microsd)
					BOOT=microsd
					;;
				*)
					echo "Unknown boot media specified. Valid options:"
					echo "microsd (microSD - at 512 byte offset)"
					return 1
					;;
			esac
			;;
		imx8mp-hummingboard-pulse)
			VARIANT=imx8mp
			DEVICE=hummingboard-pulse

			case ${FLAGS_boot} in
				microsd)
					BOOT=microsd
					;;
				*)
					echo "Unknown boot media specified. Valid options:"
					echo "microsd (microSD - at 512 byte offset)"
					return 1
					;;
			esac
			;;
		imx8mq-cubox-pulse)
			VARIANT=imx8mq
			DEVICE=cubox-pulse

			case ${FLAGS_boot} in
				microsd)
					BOOT=microsd
					;;
				*)
					echo "Unknown boot media specified. Valid options:"
					echo "microsd (microSD - at 512 byte offset)"
					return 1
					;;
			esac
			;;
		imx8mq-hummingboard-pulse)
			VARIANT=imx8mq
			DEVICE=hummingboard-pulse

			case ${FLAGS_boot} in
				microsd)
					BOOT=microsd
					;;
				*)
					echo "Unknown boot media specified. Valid options:"
					echo "microsd (microSD - at 512 byte offset)"
					return 1
					;;
			esac
			;;
		*)
			echo "Unknown device specified. Valid options:"
			echo "- imx8mp-cubox-pulse (CuBox-M)"
			echo "- imx8mp-hummingboard-pulse"
			echo "- imx8mq-cubox-pulse"
			echo "- imx8mq-hummingboard-pulse"
			return 1
			;;
	esac

	do_build_${VARIANT} $DEVICE $BOOT
	return $?
}

do_build_imx8mp() {
	DEVICE=$1
	BOOT=$2
	export BINDIR="$PWD/blobs"

	export CROSS_COMPILE=aarch64-linux-gnu-

	# ATF
	make -C build/atf_imx8mp \
		PLAT=imx8mp \
		bl31 \
		|| return 1

	export BL31="$PWD/build/atf_imx8mp/build/imx8mp/release/bl31.bin"

	# U-Boot
	pushd build/u-boot_imx8mp

	# configure
	cp configs/imx8mp_solidrun_defconfig .config
	case ${DEVICE} in
		cubox-pulse)
			printf "CONFIG_DEFAULT_FDT_FILE=\"%s\"\n" "imx8mp-cubox-pulse.dtb" >> .config
			;;
		hummingboard-pulse)
			printf "CONFIG_DEFAULT_FDT_FILE=\"%s\"\n" "imx8mp-hummingboard-pulse.dtb" >> .config
			;;
		*)
			echo "internal error :@"
			return 1
			;;
	esac
	cat >> .config << EOF
CONFIG_CMD_BOOTMENU=y
CONFIG_CMD_SETEXPR=y
EOF
	make olddefconfig || return 1

	# build
	make -j4 || return 1
	popd

	# i.MX Image Builder
	cp $BL31 build/mkimage_imx8mp/iMX8M/
	cp build/u-boot_imx8mp/arch/arm/dts/imx8mp-solidrun.dtb build/mkimage_imx8mp/iMX8M/
	cp build/u-boot_imx8mp/spl/u-boot-spl.bin build/mkimage_imx8mp/iMX8M/
	cp build/u-boot_imx8mp/tools/mkimage build/mkimage_imx8mp/iMX8M/mkimage_uboot
	cp build/u-boot_imx8mp/u-boot-nodtb.bin build/mkimage_imx8mp/iMX8M/
	cp blobs/* build/mkimage_imx8mp/iMX8M/
	pushd build/mkimage_imx8mp
	sed -i "s/\(^dtbs = \).*/\1imx8mp-solidrun.dtb/" iMX8M/soc.mak
	make clean
	make SOC=iMX8MP flash_evk
	popd

	cp -v build/mkimage_imx8mp/iMX8M/flash.bin u-boot-imx8mp-${DEVICE}-${BOOT}.bin

	return 0
}

do_build_imx8mq() {
	DEVICE=$1
	BOOT=$2
	export BINDIR="$PWD/blobs"

	export CROSS_COMPILE=aarch64-linux-gnu-

	# ATF
	make -C build/atf_imx8mq \
		PLAT=imx8mq \
		bl31 \
		|| return 1

	export BL31="$PWD/build/atf_imx8mq/build/imx8mq/release/bl31.bin"

	# U-Boot
	pushd build/u-boot_imx8mq

	# configure
	cp configs/imx8mq_hb_defconfig .config
	case ${DEVICE} in
		cubox-pulse)
			printf "CONFIG_DEFAULT_FDT_FILE=\"%s\"\n" "imx8mq-cubox-pulse" >> .config
			;;
		hummingboard-pulse)
			printf "CONFIG_DEFAULT_FDT_FILE=\"%s\"\n" "imx8mq-hummingboard-pulse" >> .config
			;;
		*)
			echo "internal error :@"
			return 1
			;;
	esac
	cat >> .config << EOF
CONFIG_CMD_BOOTMENU=y
CONFIG_CMD_SETEXPR=y
EOF
	make olddefconfig || return 1

	# build
	make flash.bin -j4 || return 1
	popd

	cp -v build/u-boot_imx8mq/flash.bin u-boot-imx8mq-${DEVICE}-${BOOT}.bin

	return 0
}

# MAIN

# create identity
git config --global user.name "SolidRun Docker Tools"
git config --global user.email "no-reply@solid-run.com"

# check for command argument(s)
if [ $# -lt 1 ]; then
	echo "No command specified."
	exit 1
fi
command="$1"
shift

case $command in
	init)
		do_init $@
		exit $?
	;;
	sync)
		do_sync $@
		exit $?
	;;
	blobs)
		do_blobs $@
		exit $?
	;;
	build)
		do_build $@
		exit $?
	;;
	*)
		echo "Unknown command $@!"
		exit 1
	;;
esac

exit 0
