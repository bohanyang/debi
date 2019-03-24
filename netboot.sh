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
      COUNTRY=$2
      shift
      ;;
    -fqdn)
      FQDN=$2
      shift
      ;;
    -proto)
      PROTO=$2
      shift
      ;;
    -host)
      HOST=$2
      shift
      ;;
    -dir)
      DIR=${2%/}
      shift
      ;;
    -suite)
      SUITE=$2
      shift
      ;;
    -u)
      ADMIN=$2
      shift
      ;;
    -p)
      PASSWD=$2
      shift
      ;;
    -tz)
      TIME_ZONE=$2
      shift
      ;;
    -ntp)
      NTP=$2
      shift
      ;;
    -s)
      SECURITY=$2
      shift
      ;;
    -upgrade)
      UPGRADE=$2
      shift
      ;;
    -ip)
      IP_ADDR=$2
      shift
      ;;
    -cidr)
      NETMASK=$2
      shift
      ;;
    -gw)
      GATEWAY=$2
      shift
      ;;
    -ns)
      DNS=$2
      shift
      ;;
    -add)
      INCLUDE=$2
      shift
      ;;
    -ssh)
      SSH_PASSWD=$2
      shift
      ;;
    -fs)
      FILESYS=$2
      shift
      ;;
    -dry-run)
      DRYRUN=true
    ;;
    -crypto)
      DISKCRYPTO="crypto"
    ;;
    -manually)
      MANUALLY=true
    ;;
    -arch)
      MACHARCH=$2
      shift
      ;;
    *)
      echo "Illegal option $1"
      exit 1
  esac
  shift
done

case "$COUNTRY" in
  CN)
    PROTO=${PROTO:-https}
    HOST=${HOST:-chinanet.mirrors.ustc.edu.cn}
    TIME_ZONE=${TIME_ZONE:-Asia/Shanghai}
    NTP=${NTP:-cn.ntp.org.cn}
    SECURITY=${SECURITY:-true}
    DNS=${DNS:-156.154.70.5 156.154.71.5}
esac

COUNTRY=${COUNTRY:-US}
PROTO=${PROTO:-http}
HOST=${HOST:-deb.debian.org}
DIR=${DIR:-/debian}
if [ -z "$SECURITY" ]; then
ARCH=$(dpkg --print-architecture)
fi
SUITE=${SUITE:-stretch}
ADMIN=${ADMIN:-debian}
TIME_ZONE=${TIME_ZONE:-UTC}
NTP=${NTP:-pool.ntp.org}
UPGRADE=${UPGRADE:-full-upgrade}
DNS=${DNS:-8.8.8.8 8.8.4.4}
FILESYS=${FILESYS:-ext4}
DISKCRYPTO=${DISKCRYPTO:-regular}

if [ -z "$SECURITY" ]; then
  SECURITY=http://security.debian.org/debian-security
else
  if [ "$SECURITY" = true ]; then
    SECURITY=$PROTO://$HOST${DIR%/*}/debian-security
  fi
fi

if [ -z "$PASSWD" ] && [ "$MANUALLY" != true ]; then
  PASSWD=$(mkpasswd -m sha-512)
else
  PASSWD=$(mkpasswd -m sha-512 "$PASSWD")
fi


if [ "$DRYRUN" != true ]; then

BOOT=/boot/debian-$SUITE
URL=$PROTO://$HOST$DIR/dists/$SUITE/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH

update-grub
rm -fr "$BOOT"
mkdir -p "$BOOT"
cd "$BOOT"

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

# 1. Localization: COUNTRY

d-i debian-installer/locale string en_US
d-i debian-installer/language string en
d-i debian-installer/country string {{-COUNTRY-}}
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# 2. Network configuration: IP_ADDR, NETMASK, GATEWAY, DNS, FQDN, SSH_PASSWD

d-i netcfg/choose_interface select auto
EOF

if [ -n "$IP_ADDR" ]; then
  echo "d-i netcfg/disable_autoconfig boolean true" >> preseed.cfg
  echo "d-i netcfg/get_ipaddress string $IP_ADDR" >> preseed.cfg
  if [ -n "$NETMASK" ]; then
    echo "d-i netcfg/get_netmask string $NETMASK" >> preseed.cfg
  fi
  if [ -n "$GATEWAY" ]; then
    echo "d-i netcfg/get_gateway string $GATEWAY" >> preseed.cfg
  fi
  if [ -n "$DNS" ]; then
    echo "d-i netcfg/get_nameservers string $DNS" >> preseed.cfg
  fi
  echo "d-i netcfg/confirm_static boolean true" >> preseed.cfg
fi

cat >> preseed.cfg << EOF
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string
EOF

if [ -n "$FQDN" ]; then
  echo "d-i netcfg/hostname string $FQDN" >> preseed.cfg
fi

cat >> preseed.cfg << EOF
d-i hw-detect/load_firmware boolean true
EOF

if [ -n "$SSH_PASSWD" ]; then
  echo "d-i anna/choose_modules string network-console" >> preseed.cfg
  echo "d-i preseed/early_command string anna-install network-console" >> preseed.cfg
  echo "d-i network-console/password password $SSH_PASSWD" >> preseed.cfg
  echo "d-i network-console/password-again password $SSH_PASSWD" >> preseed.cfg
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

if [ "$MANUALLY" != true ]; then
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

if [ "$DISKCRYPTO" = "regular" ]; then
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

if [ -n "$INCLUDE" ]; then
  echo "d-i pkgsel/include string $INCLUDE" >> preseed.cfg
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

sed -i 's/{{-COUNTRY-}}/'"$COUNTRY"'/g' preseed.cfg
sed -i 's/{{-PROTO-}}/'"$PROTO"'/g' preseed.cfg
sed -i 's/{{-HOST-}}/'"$HOST"'/g' preseed.cfg
sed -i 's/{{-DIR-}}/'$(echo "$DIR" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-SUITE-}}/'"$SUITE"'/g' preseed.cfg
sed -i 's/{{-ADMIN-}}/'"$ADMIN"'/g' preseed.cfg
sed -i 's/{{-PASSWD-}}/'$(echo "$PASSWD" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-TIME_ZONE-}}/'$(echo "$TIME_ZONE" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-NTP-}}/'"$NTP"'/g' preseed.cfg
sed -i 's/{{-SECURITY-}}/'$(echo "$SECURITY" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-UPGRADE-}}/'"$UPGRADE"'/g' preseed.cfg
sed -i 's/{{-FILESYS-}}/'"$FILESYS"'/g' preseed.cfg
sed -i 's/{{-DISKCRYPTO-}}/'"$DISKCRYPTO"'/g' preseed.cfg

if [ "$DRYRUN" != true ]; then

wget "$URL/linux" "$URL/initrd.gz"
gunzip initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd

cat >> ../grub/grub.cfg << EOF
menuentry 'New Install' {
insmod part_msdos
insmod ext2
set root='(hd0,msdos1)'
linux $BOOT/linux
initrd $BOOT/initrd.gz
}
EOF

fi
