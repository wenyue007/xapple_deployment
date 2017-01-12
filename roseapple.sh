#! /bin/bash -
SDCARD=$1
pppwd="6666jhu2"
CMD="eval echo $pppwd | sudo -S"

[ -b $SDCARD ] || { echo "Incorrect block device."; exit 1 ;}

top_path=$2
three_pig=${top_path}/bootloader
rosebin=`ls $three_pig | grep bootloader.bin`
rosebin=${three_pig}/$rosebin
echo $rosebin

rosedtb=`ls $three_pig | grep u-boot-dtb.img`
rosedtb=${three_pig}/$rosedtb
echo $rosedtb

roseimage=`ls $three_pig | grep misc.img`
roseimage=${three_pig}/$roseimage
echo $roseimage

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Preparing $SDCARD..."
$CMD umount ${SDCARD}1 >& /dev/null
$CMD umount ${SDCARD}2 >& /dev/null
$CMD parted -s ${SDCARD} mklabel gpt
$CMD parted -s ${SDCARD} unit s mkpart primary fat32 16384 147455
$CMD parted -s ${SDCARD} unit s print | tee ./big_size

echo "Copying $rosebin into $SDCARD..."
$CMD dd if=$rosebin of=${SDCARD} bs=512 seek=4097

echo "Copying $rosedtb into $SDCARD..."
$CMD dd if=$rosedtb of=${SDCARD} bs=512 seek=6144

echo "Copying $roseimage into ${SDCARD}1..."
$CMD dd if=$roseimage of=${SDCARD}1

two_dog=$top_path
rosebin=`ls $two_dog | grep bin`
rosebin=${two_dog}/$rosebin
echo $rosebin

rosedtb=`ls $two_dog | grep dtb`
rosedtb=${two_dog}/$rosedtb
echo $rosedtb

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Copying kernel and dtb into ${SDCARD}1..."
$CMD umount ${SDCARD}1 >& /dev/null
$CMD mount ${SDCARD}1 /mnt
$CMD ls -l /mnt
$CMD cp $rosebin /mnt/zImage
$CMD cp $rosedtb /mnt/kernel.dtb
$CMD rm /mnt/uImage
$CMD ls -l /mnt

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Updating uenv.txt"
cat <<"EOF" > ./uenv.txt
uenvcmd=setenv os_type linux;
loadkernel=fatload ${devtype} ${devpart} ${kernel_addr_r} zImage;
bootargs=console=ttyS2,115200 earlyprintk root=/dev/mmcblk0p2 rw ip=dhcp;
mboot=run loadkernel; run loadfdt;bootz ${kernel_addr_r} - ${fdt_addr_r};
EOF
$CMD cat /mnt/uenv.txt
$CMD cp ./uenv.txt /mnt/uenv.txt
echo "After updating that file..."
$CMD cat /mnt/uenv.txt
rm -rf ./uenv.txt
$CMD umount ${SDCARD}1

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
end_size=`cat ./big_size | grep "Disk $SDCARD:"|awk -F":" '{print $2}'`
end_size=`echo $end_size| awk -F"s" '{print $1}'`
end_size=$((end_size - 100))
#echo $end_size
roserootfs=`ls $two_dog | grep tar.bz2`
roserootfs=${two_dog}/$roserootfs
echo $roserootfs

echo "Copying rootfs into ${SDCARD}2"
(echo $pppwd; echo "unit s mkpart primary ext4 147456 $end_size"; echo Yes; echo q)|sudo -S parted ${SDCARD} 
$CMD mkfs.ext4 -L system ${SDCARD}2
$CMD mount ${SDCARD}2 /mnt
$CMD tar -C /mnt -jxvf $roserootfs --numeric-owner
$CMD umount ${SDCARD}2 
rm -rf ./big_size

echo "Done"
