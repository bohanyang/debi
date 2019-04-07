#!/usr/bin/env sh

# Copyright 2018 Brent, Yang Bohan

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.

# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

while [ $# -gt 0 ]; do
  case $1 in
    -c)
      DEBNETB_COUNTRY=$2
      shift
      ;;
    -fqdn)
      DEBNETB_FQDN=$2
      shift
      ;;
    -proto)
      DEBNETB_PROTO=$2
      shift
      ;;
    -host)
      DEBNETB_HOST=$2
      shift
      ;;
    -dir)
      DEBNETB_DIR=${2%/}
      shift
      ;;
    -suite)
      DEBNETB_SUITE=$2
      shift
      ;;
    -u)
      DEBNETB_ADMIN=$2
      shift
      ;;
    -p)
      DEBNETB_PASSWD=$2
      shift
      ;;
    -tz)
      DEBNETB_TIME_ZONE=$2
      shift
      ;;
    -ntp)
      DEBNETB_NTP=$2
      shift
      ;;
    -s)
      DEBNETB_SECURITY=$2
      shift
      ;;
    -upgrade)
      DEBNETB_UPGRADE=$2
      shift
      ;;
    -ip)
      DEBNETB_IP_ADDR=$2
      shift
      ;;
    -cidr)
      DEBNETB_NETMASK=$2
      shift
      ;;
    -gw)
      DEBNETB_GATEWAY=$2
      shift
      ;;
    -ns)
      DEBNETB_DNS=$2
      shift
      ;;
    -add)
      DEBNETB_INCLUDE=$2
      shift
      ;;
    -ssh)
      DEBNETB_SSH_PASSWD=$2
      shift
      ;;
    -fs)
      DEBNETB_FILESYS=$2
      shift
      ;;
    -dry-run)
      DEBNETB_DRYRUN=true
    ;;
    -crypto)
      DEBNETB_DISKCRYPTO="crypto"
    ;;
    -manually)
      DEBNETB_MANUALLY=true
    ;;
    -arch)
      DEBNETB_ARCH=$2
      shift
    ;;
    -lvm)
      DEBNETB_ISLVM=true
    ;;
    *)
      echo "Illegal option $1"
      exit 1
  esac
  shift
done

case "$DEBNETB_COUNTRY" in
  CN)
    DEBNETB_PROTO=${DEBNETB_PROTO:-https}
    DEBNETB_HOST=${DEBNETB_HOST:-chinanet.mirrors.ustc.edu.cn}
    DEBNETB_TIME_ZONE=${DEBNETB_TIME_ZONE:-Asia/Shanghai}
    DEBNETB_NTP=${DEBNETB_NTP:-cn.ntp.org.cn}
    DEBNETB_SECURITY=${DEBNETB_SECURITY:-true}
    DEBNETB_DNS=${DEBNETB_DNS:-156.154.70.5 156.154.71.5}
esac

DEBNETB_COUNTRY=${DEBNETB_COUNTRY:-US}
DEBNETB_PROTO=${DEBNETB_PROTO:-http}
DEBNETB_HOST=${DEBNETB_HOST:-deb.debian.org}
DEBNETB_DIR=${DEBNETB_DIR:-/debian}
if [ -z "$DEBNETB_ARCH" ]; then
DEBNETB_ARCH=$(dpkg --print-architecture)
fi
DEBNETB_SUITE=${DEBNETB_SUITE:-stretch}
DEBNETB_ADMIN=${DEBNETB_ADMIN:-debian}
DEBNETB_TIME_ZONE=${DEBNETB_TIME_ZONE:-UTC}
DEBNETB_NTP=${DEBNETB_NTP:-pool.ntp.org}
DEBNETB_UPGRADE=${DEBNETB_UPGRADE:-full-upgrade}
DEBNETB_DNS=${DEBNETB_DNS:-8.8.8.8 8.8.4.4}
DEBNETB_FILESYS=${DEBNETB_FILESYS:-ext4}
DEBNETB_DISKCRYPTO=${DEBNETB_DISKCRYPTO:-regular}

if [ -z "$DEBNETB_SECURITY" ]; then
  DEBNETB_SECURITY=http://security.debian.org/debian-security
else
  if [ "$DEBNETB_SECURITY" = true ]; then
    DEBNETB_SECURITY=$DEBNETB_PROTO://$DEBNETB_HOST${DEBNETB_DIR%/*}/debian-security
  fi
fi

if [ "$DEBNETB_MANUALLY" != true ]; then
if [ -z "$DEBNETB_PASSWD" ]; then
  DEBNETB_PASSWD=$(mkpasswd -m sha-512)
else
  DEBNETB_PASSWD=$(mkpasswd -m sha-512 "$DEBNETB_PASSWD")
fi
fi


if [ "$DEBNETB_DRYRUN" != true ]; then
DEBNETB_BOOTNAME="debian-$DEBNETB_SUITE"
if [ "$DEBNETB_ISLVM" = true ]; then
DEBNETB_BOOTROOT=/
else
DEBNETB_BOOTROOT=/boot/
fi
DEBNETB_BOOT="/boot/$DEBNETB_BOOTNAME"
DEBNETB_OUTPUTBOOT="$DEBNETB_BOOTROOT$DEBNETB_BOOTNAME"
DEBNETB_URL=$DEBNETB_PROTO://$DEBNETB_HOST$DEBNETB_DIR/dists/$DEBNETB_SUITE/main/installer-$DEBNETB_ARCH/current/images/netboot/debian-installer/$DEBNETB_ARCH
if type update-grub >/dev/null; then
update-grub
DEBNETB_GRUBCFG=/boot/grub/grub.cfg
else
DEBNETB_GRUBCFG=/boot/grub2/grub.cfg
grub2-mkconfig > "$DEBNETB_GRUBCFG"
fi
rm -fr "$DEBNETB_BOOT"
mkdir -p "$DEBNETB_BOOT"
cd "$DEBNETB_BOOT"
fi

cat >> preseed.cfg << EOF
# COUNTRY: 1
# IP_ADDR: 2
# NETMASK: 2
# GATEWAY: 2
# DNS: 2
# FQDN: 2
# SSH_PASSWD: 2
# PROTO: 3
# HOST: 3
# DIR: 3
# SUITE: 3, 8
# ADMIN: 4
# PASSWD: 4
# TIME_ZONE: 5
# NTP: 5
# FILESYS: 6
# DISKCRYPTO: 6
# SECURITY: 8
# INCLUDE: 9
# UPGRADE: 9

# 1. Localization:

d-i debian-installer/language string en
d-i debian-installer/country string {{-COUNTRY-}}
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# 2. Network configuration: IP_ADDR, NETMASK, GATEWAY, DNS, FQDN, SSH_PASSWD

d-i netcfg/choose_interface select auto
EOF

if [ -n "$DEBNETB_IP_ADDR" ]; then
  echo "d-i netcfg/disable_autoconfig boolean true" >> preseed.cfg
  echo "d-i netcfg/get_ipaddress string $DEBNETB_IP_ADDR" >> preseed.cfg
  if [ -n "$DEBNETB_NETMASK" ]; then
    echo "d-i netcfg/get_netmask string $DEBNETB_NETMASK" >> preseed.cfg
  fi
  if [ -n "$DEBNETB_GATEWAY" ]; then
    echo "d-i netcfg/get_gateway string $DEBNETB_GATEWAY" >> preseed.cfg
  fi
  if [ -n "$DEBNETB_DNS" ]; then
    echo "d-i netcfg/get_nameservers string $DEBNETB_DNS" >> preseed.cfg
  fi
  echo "d-i netcfg/confirm_static boolean true" >> preseed.cfg
fi

cat >> preseed.cfg << EOF
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string
EOF

if [ -n "$DEBNETB_FQDN" ]; then
  echo "d-i netcfg/hostname string $DEBNETB_FQDN" >> preseed.cfg
fi

cat >> preseed.cfg << EOF
d-i hw-detect/load_firmware boolean true
EOF

if [ -n "$DEBNETB_SSH_PASSWD" ]; then
  echo "d-i anna/choose_modules string network-console" >> preseed.cfg
  echo "d-i preseed/early_command string anna-install network-console" >> preseed.cfg
  echo "d-i network-console/password password $DEBNETB_SSH_PASSWD" >> preseed.cfg
  echo "d-i network-console/password-again password $DEBNETB_SSH_PASSWD" >> preseed.cfg
  echo "d-i network-console/start select Continue" >> preseed.cfg
fi

cat >> preseed.cfg << EOF

# 3. Mirror settings: PROTO, HOST, DIR, SUITE

d-i mirror/country string manual
d-i mirror/protocol string {{-PROTO-}}
d-i mirror/{{-PROTO-}}/hostname string {{-HOST-}}
d-i mirror/{{-PROTO-}}/directory string {{-DIR-}}
d-i mirror/{{-PROTO-}}/proxy string
d-i mirror/suite string {{-SUITE-}}
d-i mirror/udeb/suite string {{-SUITE-}}
EOF

if [ "$DEBNETB_MANUALLY" != true ]; then
cat >> preseed.cfg << EOF

# 4. Account setup: ADMIN, PASSWD

d-i passwd/root-login boolean false
d-i passwd/user-fullname string
d-i passwd/username string {{-ADMIN-}}
d-i passwd/user-password-crypted password {{-PASSWD-}}

# 5. Clock and time zone setup: TIME_ZONE, NTP

d-i clock-setup/utc boolean true
d-i time/zone string {{-TIME_ZONE-}}
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string {{-NTP-}}
EOF

cat >> preseed.cfg << EOF

# 6. Partitioning: FILESYS

d-i partman-basicfilesystems/no_swap boolean false
d-i partman/default_filesystem string {{-FILESYS-}}
d-i partman-auto/method string {{-DISKCRYPTO-}}
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
EOF

if [ "$DEBNETB_DISKCRYPTO" = "regular" ]; then
cat >> preseed.cfg << EOF
d-i partman-auto/expert_recipe string naive :: 0 1 -1 \$default_filesystem \$primary{ } \$bootable{ } method{ format } format{ } use_filesystem{ } \$default_filesystem{ } mountpoint{ / } .
d-i partman-auto/choose_recipe select naive
EOF
fi

cat >> preseed.cfg << EOF
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/mount_style select uuid
EOF

cat >> preseed.cfg << EOF

# 7. Base system installation

d-i base-installer/install-recommends boolean false

# 8. Apt setup: SECURITY, SUITE

d-i apt-setup/services-select multiselect updates
d-i apt-setup/local0/repository string {{-SECURITY-}} {{-SUITE-}}/updates main
d-i apt-setup/local0/source boolean true

# 9. Package selection: INCLUDE, UPGRADE

tasksel tasksel/first multiselect ssh-server
EOF

if [ -n "$DEBNETB_INCLUDE" ]; then
  echo "d-i pkgsel/include string $DEBNETB_INCLUDE" >> preseed.cfg
fi

cat >> preseed.cfg << EOF
d-i pkgsel/upgrade select {{-UPGRADE-}}
popularity-contest popularity-contest/participate boolean false

# 10. Boot loader installation

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default

# 11. Finishing up the installation

d-i finish-install/reboot_in_progress note
EOF
fi

sed -i 's/{{-COUNTRY-}}/'"$DEBNETB_COUNTRY"'/g' preseed.cfg
sed -i 's/{{-PROTO-}}/'"$DEBNETB_PROTO"'/g' preseed.cfg
sed -i 's/{{-HOST-}}/'"$DEBNETB_HOST"'/g' preseed.cfg
sed -i 's/{{-DIR-}}/'$(echo "$DEBNETB_DIR" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-SUITE-}}/'"$DEBNETB_SUITE"'/g' preseed.cfg
sed -i 's/{{-ADMIN-}}/'"$DEBNETB_ADMIN"'/g' preseed.cfg
sed -i 's/{{-PASSWD-}}/'$(echo "$DEBNETB_PASSWD" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-TIME_ZONE-}}/'$(echo "$DEBNETB_TIME_ZONE" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-NTP-}}/'"$DEBNETB_NTP"'/g' preseed.cfg
sed -i 's/{{-SECURITY-}}/'$(echo "$DEBNETB_SECURITY" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-UPGRADE-}}/'"$DEBNETB_UPGRADE"'/g' preseed.cfg
sed -i 's/{{-FILESYS-}}/'"$DEBNETB_FILESYS"'/g' preseed.cfg
sed -i 's/{{-DISKCRYPTO-}}/'"$DEBNETB_DISKCRYPTO"'/g' preseed.cfg

if [ "$DEBNETB_DRYRUN" != true ]; then

wget "$DEBNETB_URL/linux" "$DEBNETB_URL/initrd.gz"
gunzip initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd

cat >> "$DEBNETB_GRUBCFG" << EOF
menuentry 'New Install' --id debian-netboot-installer {
insmod part_msdos
insmod ext2
set root='(hd0,msdos1)'
linux $DEBNETB_OUTPUTBOOT/linux
initrd $DEBNETB_OUTPUTBOOT/initrd.gz
}
EOF

fi
