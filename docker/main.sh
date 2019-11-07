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

do_build() {
	if [ ! -d build ]; then
		echo "Error: not initialized, run init first!"
		return 1
	fi
	if [ ! -d build/edk2 ] || [ ! -d build/atf ] || [ ! -d build/binaries ] || [ ! -d build/mv_ddr ]; then
		echo "Error: Sources not complete, run sync first!"
		return 1
	fi

	# flags
	. /shflags
	DEFINE_string 'device' mcbin 'Device to build for' 'd'
	DEFINE_string 'boot' spi 'Boot media to build for' 'b'
	FLAGS "$@" || exit 1
	eval set -- "${FLAGS_ARGV}"

	export CROSS_COMPILE=aarch64-linux-gnu-

	# EDK2
	pushd build
	export WORKSPACE=$PWD
	export PACKAGES_PATH=$PWD/edk2:$PWD/edk2-platforms
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-

	# TODO: remove this HACK
	#rm -f edk2-platforms && ln -sv ../edk2-platforms ./
	#mkdir -p Build/Armada80x0McBin-AARCH64/RELEASE_GCC5/AARCH64
	#rm -f Build/Armada80x0McBin-AARCH64/RELEASE_GCC5/AARCH64/Silicon && ln -sv edk2-platforms/Silicon Build/Armada80x0McBin-AARCH64/RELEASE_GCC5/AARCH64/Silicon

	# configure
	case ${FLAGS_boot} in
		spi)
			;;
		*)
			echo "Unknown boot media specified. Valid options:"
			echo "spi (SPI Flash)"
			return 1
			;;
	esac
	case ${FLAGS_device} in
		mcbin)
			;;
		*)
			echo "Unknown device specified. Valid options:"
			echo "- mcbin (MacchiatoBIN)"
			return 1
			;;
	esac

	# build
	make -C edk2/BaseTools || return 1
	source edk2/edksetup.sh
	build -a AARCH64 -b RELEASE -t GCC5 -p Platform/SolidRun/Armada80x0McBin/Armada80x0McBin.dsc -v || return 1
	popd

	# ATF
	make -C build/atf \
		PLAT=a80x0_mcbin \
		MV_DDR_PATH=$PWD/build/mv_ddr \
		SCP_BL2=$PWD/build/binaries/mrvl_scp_bl2.img \
		BL33=$PWD/build/Build/Armada80x0McBin-AARCH64/RELEASE_GCC5/FV/ARMADA_EFI.fd \
		all fip \
		|| return 1

	cp -v build/atf/build/a80x0_mcbin/release/flash-image.bin uefi-${FLAGS_device}-${FLAGS_boot}.bin

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
