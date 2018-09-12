#!/bin/sh

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
      USERNAME=$2
      shift
      ;;
    -p)
      PASSWD=$2
      shift
      ;;
    -tz)
      TIMEZONE=$2
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
    --upgrade)
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
    TIMEZONE=${TIMEZONE:-Asia/Shanghai}
    NTP=${NTP:-ntp1.aliyun.com}
    SECURITY=${SECURITY:-true}
esac

COUNTRY=${COUNTRY:-US}
FQDN=${FQDN:-localhost}
PROTO=${PROTO:-https}
HOST=${HOST:-dpvctowv9b08b.cloudfront.net}
DIR=${DIR:-/debian}
ARCH=$(dpkg --print-architecture)
SUITE=${SUITE:-stretch}
USERNAME=${USERNAME:-ubuntu}
TIMEZONE=${TIMEZONE:-UTC}
NTP=${NTP:-time.google.com}
UPGRADE=${UPGRADE:-full-upgrade}
DNS=${DNS:-1.1.1.1 156.154.70.5 8.8.8.8}

if [ -z "$SECURITY" ]; then
  SECURITY=https://dpvctowv9b08b.cloudfront.net/debian-security
else
  if [ "$SECURITY" = true ]; then
    SECURITY=$PROTO://$HOST${DIR%/*}/debian-security
  fi
fi

if [ -z "$PASSWD" ]; then
  PASSWD=$(mkpasswd -m sha-512)
else
  PASSWD=$(mkpasswd -m sha-512 "$PASSWD")
fi

BOOT=/boot/debian-$SUITE
URL=$PROTO://$HOST$DIR/dists/$SUITE/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH

update-grub
rm -fr "$BOOT"
mkdir -p "$BOOT"
cd "$BOOT"

cat >> preseed.cfg << EOF
# COUNTRY: 1
# FQDN: 2
# PROTO: 3
# HOST: 3
# DIR: 3
# SUITE: 3, 8
# USERNAME: 4
# PASSWD: 4
# TIMEZONE: 5
# NTP: 5
# SECURITY: 8
# UPGRADE: 9

# 1. Localization: COUNTRY

d-i debian-installer/locale string en_US
d-i debian-installer/language string en
d-i debian-installer/country string {{-COUNTRY-}}
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# 2. Network configuration: FQDN

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
d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain
d-i netcfg/hostname string {{-FQDN-}}
d-i hw-detect/load_firmware boolean true

# 3. Mirror settings: PROTO, HOST, DIR, SUITE

d-i mirror/country string manual
d-i mirror/protocol string {{-PROTO-}}
d-i mirror/{{-PROTO-}}/hostname string {{-HOST-}}
d-i mirror/{{-PROTO-}}/directory string {{-DIR-}}
d-i mirror/{{-PROTO-}}/proxy string
d-i mirror/suite string {{-SUITE-}}
d-i mirror/udeb/suite string {{-SUITE-}}

# 4. Account setup: USERNAME, PASSWD

d-i passwd/root-login boolean false
d-i passwd/user-fullname string
d-i passwd/username string {{-USERNAME-}}
d-i passwd/user-password-crypted password {{-PASSWD-}}

# 5. Clock and time zone setup: TIMEZONE, NTP

d-i clock-setup/utc boolean true
d-i time/zone string {{-TIMEZONE-}}
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string {{-NTP-}}

# 6. Partitioning

d-i partman-basicfilesystems/no_swap boolean false
d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/expert_recipe string naive :: 0 1 -1 ext4 $primary{ } $bootable{ } method{ format } format{ } use_filesystem{ } filesystem{ ext4 } mountpoint{ / } .
d-i partman-auto/choose_recipe select naive
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/mount_style select uuid

# 7. Base system installation

d-i base-installer/install-recommends boolean false

# 8. Apt setup: SECURITY, SUITE

d-i apt-setup/services-select multiselect updates
d-i apt-setup/local0/repository string {{-SECURITY-}} {{-SUITE-}}/updates main
d-i apt-setup/local0/source boolean true

# 9. Package selection: TASKS, UPGRADE

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
EOF

sed -i 's/{{-COUNTRY-}}/'"$COUNTRY"'/g' preseed.cfg
sed -i 's/{{-FQDN-}}/'"$FQDN"'/g' preseed.cfg
sed -i 's/{{-PROTO-}}/'"$PROTO"'/g' preseed.cfg
sed -i 's/{{-HOST-}}/'"$HOST"'/g' preseed.cfg
sed -i 's/{{-DIR-}}/'$(echo "$DIR" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-SUITE-}}/'"$SUITE"'/g' preseed.cfg
sed -i 's/{{-USERNAME-}}/'"$USERNAME"'/g' preseed.cfg
sed -i 's/{{-PASSWD-}}/'$(echo "$PASSWD" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-TIMEZONE-}}/'$(echo "$TIMEZONE" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-NTP-}}/'"$NTP"'/g' preseed.cfg
sed -i 's/{{-SECURITY-}}/'$(echo "$SECURITY" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-UPGRADE-}}/'"$UPGRADE"'/g' preseed.cfg

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
