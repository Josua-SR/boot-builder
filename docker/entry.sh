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

# include shFlags library
. shflags

# declare flags
DEFINE_integer 'uid' 1000 'User ID to run as' 'u'
DEFINE_integer 'gid' 100 'Group ID to run as' 'g'
DEFINE_string 'device' mcbin 'Device to build for' 'd'
DEFINE_string 'boot' generic 'Boot media to build for' 'b'

# parse flags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# check arguments
case ${FLAGS_device} in
    cfgt)
        DEVICE=cfgt
        DEVICE_LONG="Clearfog GT 8k"
        ;;
    mcbin)
        DEVICE=mcbin
        DEVICE_LONG="MacchiatoBIN"
        ;;
    *)
        echo "ERROR: Unknown argument to device: ${FLAGS_device}"
        exit 1
        ;;
esac
case ${FLAGS_boot} in
    generic)
        ;;
    microsd)
        ;;
    *)
        echo "ERROR: Unknown argument to boot: ${FLAGS_boot}"
        exit 1
        ;;
esac

# declare disk image size
SIZE=0x800000

# functions
gen_fdisk_args() {
    # empty partition table
    printf "o\n"

    # first partition, full disk
    start=4096
    end=$((SIZE/512-1))
    printf "n\np\n%i\n%i\n%i\n" 1 $start $end

    # set type t0 0x0c
    printf "t\n%s\n" 0c
    # Note: no confirmation prompt with one partition

    # write and quit
    printf "w\nq\n"
}

# create fat image
qemu-img create fs.img $((SIZE-2048*512))
mkfs.vfat -n "UBOOT INSTALLER" fs.img

# add boot script
sed -e "s;@DEVICE@;${DEVICE};g" -e "s;@DEVICE_LONG@;${DEVICE_LONG};g" -e "w boot.txt" -n /work/bootscr-menu.txt
mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -d boot.txt boot.scr >/dev/null
mcopy -v -i fs.img boot.scr ::

# add u-boot binaries
mcopy -v -i fs.img /work/u-boot-${DEVICE}-emmc_data.bin ::
mcopy -v -i fs.img /work/u-boot-${DEVICE}-microsd.bin ::
mcopy -v -i fs.img /work/u-boot-${DEVICE}-spi.bin ::

# create disk image
qemu-img create disk.img $SIZE
gen_fdisk_args | fdisk disk.img >/dev/null

case ${FLAGS_boot} in
    microsd)
        # add bootloader
        dd of=disk.img if=/work/u-boot-${DEVICE}-microsd.bin bs=512 seek=1 conv=notrunc 2>/dev/null

        # create environment
        qemu-img create env.img 0x10000

        # customize bootcmd
        fw_setenv -c /app/uenv.conf bootcmd 'env default -a; run bootcmd_mmc1'
        fw_setenv -c /app/uenv.conf bootdelay 0

        # add environment
        # CONFIG_ENV_OFFSET=0x180000
        dd of=disk.img if=env.img bs=512 seek=3072 conv=notrunc 2>/dev/null
        ;;
esac

# add fat partition
dd of=disk.img if=fs.img bs=512 seek=4096 conv=notrunc 2>/dev/null

# copy to working directory
chown ${FLAGS_uid}:${FLAGS_gid} disk.img
cp -v --preserve=ownership disk.img /work/u-boot-installer-${FLAGS_device}-${FLAGS_boot}.img
