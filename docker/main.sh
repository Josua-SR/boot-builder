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
	repo init -u file:///work -b $(cat /work/.git/HEAD | cut -d' ' -f2)
	status=$?
	popd

	if [ $status -ne 0 ]; then rm -rf build; fi

	return $status
}

do_sync() {
	if [ ! -d build ]; then
		echo "Error: not initialized, run init first!"
		return 1
	fi

	pushd build
	repo sync
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
	file=firmware-imx-8.8.bin
	dir=firmware-imx-8.8
	sha256sum=5ca1f8b6e6b191594d17ac7b51c38cdbc2ff808d15568ab4b0bbeb5dc6c621f6

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
	if [ ! -d build/u-boot ] || [ ! -d build/atf ]; then
		echo "Error: Sources not complete, run sync first!"
		return 1
	fi
	if [ ! -d blobs ]; then
		echo "Error: Binary blobs missing, run blobs first!"
		return 1
	fi
	export BINDIR="$PWD/blobs"

	# flags
	. /shflags
	DEFINE_string 'device' hbp 'Device to build for' 'd'
	DEFINE_string 'boot' microsd 'Boot media to build for' 'b'
	FLAGS "$@" || exit 1
	eval set -- "${FLAGS_ARGV}"

	export CROSS_COMPILE=aarch64-linux-gnu-

	# ATF
	make -C build/atf \
		PLAT=imx8mm \
		bl31 \
		|| return 1

	# U-Boot
	pushd build/u-boot

	# configure
	cp configs/imx8mm_solidrun_defconfig .config
	case ${FLAGS_boot} in
		microsd)
			;;
		*)
			echo "Unknown boot media specified. Valid options:"
			echo "microsd (microSD - at 512 byte offset)"
			return 1
			;;
	esac
	case ${FLAGS_device} in
		hbp)
			;;
		*)
			echo "Unknown device specified. Valid options:"
			echo "- hbp (Hummingboard Pulse)"
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
	cp build/atf/build/imx8mm/release/bl31.bin build/imx-mkimage/iMX8M/
	cp build/u-boot/arch/arm/dts/imx8mm-hummingboard-pulse.dtb build/imx-mkimage/iMX8M/
	cp build/u-boot/spl/u-boot-spl.bin build/imx-mkimage/iMX8M/
	cp build/u-boot/tools/mkimage build/imx-mkimage/iMX8M/mkimage_uboot
	cp build/u-boot/u-boot-nodtb.bin build/imx-mkimage/iMX8M/
	cp blobs/* build/imx-mkimage/iMX8M/
	pushd build/imx-mkimage
	#sed "s/\(^dtbs = \).*/\1fsl-imx8mm-solidrun.dtb/;s/\(mkimage\)_uboot/\1_imx8/" soc.mak > Makefile
	sed -i "s/\(^dtbs = \).*/\1imx8mm-hummingboard-pulse.dtb/" iMX8M/soc.mak
	make clean
	make SOC=iMX8MM flash_evk
	popd

	cp -v build/imx-mkimage/iMX8M/flash.bin u-boot-${FLAGS_device}-${FLAGS_boot}.bin

	return 0
}

# MAIN

# create identity
git config --global user.name "SolidRun Docker Tools"
git config --global user.email "no-reply@solid-run.com"

# check working directory
if [ ! -d .git ]; then
	echo "Error: Current directory is not a git clone"
	exit 1
fi

# check for command argument(s)
if [ $# -lt 1 ]; then
	echo "No command specified."
	exit 1
fi
command="$1"
shift

case $command in
	init)
		do_init
		exit $?
	;;
	sync)
		do_sync
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
