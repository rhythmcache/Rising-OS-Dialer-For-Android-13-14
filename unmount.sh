#!/sbin/sh
#
# Copyright © 2020-2021 Nemesis Team
#

is_mounted() { mount | grep -q " $1 "; }

abort() {
  sleep 1
  sleep 3
  exit 1;
}

sleep 1
dynamic_partitions=`getprop ro.boot.dynamic_partitions`
SLOT=`getprop ro.boot.slot_suffix`

if [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
  MOUNT_POINT=/system_root
else
  MOUNT_POINT=/system
fi

for p in "/cache" "/data" "$MOUNT_POINT" "/product" "/system_ext" "/vendor"; do
  if [ -d "$p" ] && grep -q "$p" "/etc/fstab" && ! is_mounted "$p"; then
    mount "$p"
  fi
done

if [ "$dynamic_partitions" = "true" ]; then
  for m in "/system" "/system_root" "/product" "/system_ext" "/vendor"; do
    (umount "$m"
    umount -l "$m") 2>/dev/null
  done
  mount -o ro -t auto /dev/block/mapper/system$SLOT /system_root
  mount -o ro -t auto /dev/block/mapper/vendor$SLOT /vendor 2>/dev/null
  mount -o ro -t auto /dev/block/mapper/product$SLOT /product 2>/dev/null
  mount -o ro -t auto /dev/block/mapper/system_ext$SLOT /system_ext 2>/dev/null
 else
  mount -o ro -t auto /dev/block/bootdevice/by-name/system$SLOT $MOUNT_POINT 2>/dev/null
fi

if [ "$dynamic_partitions" = "true" ]; then
  for block in system vendor product system_ext; do
    for slot in "" _a _b; do
      blockdev --setrw /dev/block/mapper/$block$slot 2>/dev/null
    done
  done
  mount -o rw,remount -t auto /dev/block/mapper/system$SLOT /system_root
  mount -o rw,remount -t auto /dev/block/mapper/vendor$SLOT /vendor 2>/dev/null
  mount -o rw,remount -t auto /dev/block/mapper/product$SLOT /product 2>/dev/null
  mount -o rw,remount -t auto /dev/block/mapper/system_ext$SLOT /system_ext 2>/dev/null
else
  mount -o rw,remount -t auto $MOUNT_POINT
  mount -o rw,remount -t auto /vendor 2>/dev/null
  mount -o rw,remount -t auto /product 2>/dev/null
  mount -o rw,remount -t auto /system_ext 2>/dev/null
fi

sleep 0.3

unmount_all() {
  for m in "/system" "/system_root" "/product" "/system_ext" "/vendor"; do
    if [ -e $m ]; then
      (umount $m
      umount -l $m) 2>/dev/null
    fi
  done
}

unmount_all

exit 1
