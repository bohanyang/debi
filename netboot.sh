#!/usr/bin/env sh

# Copyright 2018-present Brent, Yang Bohan

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.

# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

# See the License for the specific language governing permissions and
# limitations under the License.

set -e

command_exists() {
	$sudo command -v "$@" > /dev/null 2>&1
}

user="$(id -un 2>/dev/null || true)"

sudo=''
if [ "$user" != 'root' ]; then
  if command_exists sudo; then
    sudo='sudo'
  else
    exit 1
  fi
fi

while [ $# -gt 0 ]; do
  case $1 in
    --template)
      DEBI_TEMPLATE=$2
      shift
      ;;
    --hostname)
      DEBI_HOSTNAME=$2
      shift
      ;;
    --protocol)
      DEBI_PROTOCOL=$2
      shift
      ;;
    --mirror)
      DEBI_MIRROR=$2
      shift
      ;;
    --directory)
      DEBI_DIRECTORY=${2%/}
      shift
      ;;
    --suite)
      DEBI_SUITE=$2
      shift
      ;;
    --username)
      DEBI_USERNAME=$2
      shift
      ;;
    --password)
      DEBI_PASSWORD=$2
      shift
      ;;
    --timezone)
      DEBI_TIMEZONE=$2
      shift
      ;;
    --ntp-server)
      DEBI_NTP_SERVER=$2
      shift
      ;;
    --security-mirror)
      DEBI_SECURITY_MIRROR=$2
      shift
      ;;
    --upgrade)
      DEBI_UPGRADE=$2
      shift
      ;;
    --ip)
      DEBI_IP=$2
      shift
      ;;
    --netmask)
      DEBI_NETMASK=$2
      shift
      ;;
    --gateway)
      DEBI_GATEWAY=$2
      shift
      ;;
    --dns)
      DEBI_DNS=$2
      shift
      ;;
    --include)
      DEBI_INCLUDE=$2
      shift
      ;;
    --ssh-password)
      DEBI_SSH=true
      DEBI_SSH_PASSWORD=$2
      shift
      ;;
    --ssh-keys)
      DEBI_SSH=true
      DEBI_SSH_KEYS=$2
      shift
      ;;
    --filesystem)
      DEBI_FILESYSTEM=$2
      shift
      ;;
    --dry-run)
      DEBI_DRY_RUN=true
      ;;
    --disk-encryption)
      DEBI_DISK_ENCRYPTION="crypto"
      ;;
    --manual)
      DEBI_MANUAL=true
      ;;
    --architecture)
      DEBI_ARCHITECTURE=$2
      shift
      ;;
    --boot-partition)
      DEBI_BOOT_PARTITION=true
      ;;
    --poweroff)
      DEBI_POWEROFF=true
      ;;
    *)
      echo "Illegal option $1"
      exit 1
  esac
  shift
done

case "$DEBI_TEMPLATE" in
  china)
    DEBI_PROTOCOL=${DEBI_PROTOCOL:-https}
    DEBI_MIRROR=${DEBI_MIRROR:-chinanet.mirrors.ustc.edu.cn}
    DEBI_TIMEZONE=${DEBI_TIMEZONE:-Asia/Shanghai}
    DEBI_NTP_SERVER=${DEBI_NTP_SERVER:-cn.ntp.org.cn}
    DEBI_SECURITY_MIRROR=${DEBI_SECURITY_MIRROR:-true}
    DEBI_DNS=${DEBI_DNS:-156.154.70.5 156.154.71.5}
    ;;
  cloud)
    DEBI_PROTOCOL=${DEBI_PROTOCOL:-https}
    DEBI_MIRROR=${DEBI_MIRROR:-cdn-aws.deb.debian.org}
    DEBI_NTP_SERVER=${DEBI_NTP_SERVER:-time.google.com}
    DEBI_SECURITY_MIRROR=${DEBI_SECURITY_MIRROR:-true}
esac

DEBI_PROTOCOL=${DEBI_PROTOCOL:-http}
DEBI_MIRROR=${DEBI_MIRROR:-deb.debian.org}
DEBI_DIRECTORY=${DEBI_DIRECTORY:-/debian}

if [ -z "$DEBI_ARCHITECTURE" ]; then
  if command_exists dpkg; then
    DEBI_ARCHITECTURE=$(dpkg --print-architecture)
  else
    DEBI_ARCHITECTURE=amd64
  fi
fi

DEBI_SUITE=${DEBI_SUITE:-stretch}
DEBI_USERNAME=${DEBI_USERNAME:-debian}
DEBI_TIMEZONE=${DEBI_TIMEZONE:-UTC}
DEBI_NTP_SERVER=${DEBI_NTP_SERVER:-pool.ntp.org}
DEBI_UPGRADE=${DEBI_UPGRADE:-full-upgrade}
DEBI_DNS=${DEBI_DNS:-1.1.1.1 1.0.0.1}
DEBI_FILESYSTEM=${DEBI_FILESYSTEM:-ext4}
DEBI_DISK_ENCRYPTION=${DEBI_DISK_ENCRYPTION:-regular}

if [ -z "$DEBI_SECURITY_MIRROR" ]; then
  DEBI_SECURITY_MIRROR=http://security.debian.org/debian-security
else
  if [ "$DEBI_SECURITY_MIRROR" = true ]; then
    DEBI_SECURITY_MIRROR=$DEBI_PROTOCOL://$DEBI_MIRROR${DEBI_DIRECTORY%/*}/debian-security
  fi
fi

if [ "$DEBI_MANUAL" != true ]; then
  if [ -z "$DEBI_PASSWORD" ]; then
    DEBI_PASSWORD=$(mkpasswd -m sha-512)
  else
    DEBI_PASSWORD=$(mkpasswd -m sha-512 "$DEBI_PASSWORD")
  fi
fi

DEBI_TARGET="debian-$DEBI_SUITE"
if [ "$DEBI_BOOT_PARTITION" = true ]; then
  DEBI_BOOT_DIRECTORY=/
else
  DEBI_BOOT_DIRECTORY=/boot/
fi
DEBI_TARGET_PATH="$DEBI_BOOT_DIRECTORY$DEBI_TARGET"

echo='cat'
if [ "$DEBI_DRY_RUN" != true ]; then
  DEBI_WORKDIR="/boot/$DEBI_TARGET"
  DEBI_BASE_URL=$DEBI_PROTOCOL://$DEBI_MIRROR$DEBI_DIRECTORY/dists/$DEBI_SUITE/main/installer-$DEBI_ARCHITECTURE/current/images/netboot/debian-installer/$DEBI_ARCHITECTURE
  if command_exists update-grub; then
    $sudo update-grub
    DEBI_GRUB_CONFIG=/boot/grub/grub.cfg
  else
    DEBI_GRUB_CONFIG=/boot/grub2/grub.cfg
    $sudo grub2-mkconfig -o "$DEBI_GRUB_CONFIG"
  fi
  $sudo rm -rf "$DEBI_WORKDIR"
  $sudo mkdir -p "$DEBI_WORKDIR"
  cd "$DEBI_WORKDIR"
  $sudo rm -f preseed.cfg
  echo="$sudo tee -a preseed.cfg"
fi

$echo << EOF
# Localization

d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network configuration

d-i netcfg/choose_interface select auto
EOF

if [ -n "$DEBI_IP" ]; then
  echo "d-i netcfg/disable_autoconfig boolean true" | $echo
  echo "d-i netcfg/get_ipaddress string $DEBI_IP" | $echo
  if [ -n "$DEBI_NETMASK" ]; then
    echo "d-i netcfg/get_netmask string $DEBI_NETMASK" | $echo
  fi
  if [ -n "$DEBI_GATEWAY" ]; then
    echo "d-i netcfg/get_gateway string $DEBI_GATEWAY" | $echo
  fi
  if [ -n "$DEBI_DNS" ]; then
    echo "d-i netcfg/get_nameservers string $DEBI_DNS" | $echo
  fi
  echo "d-i netcfg/confirm_static boolean true" | $echo
fi

$echo << EOF
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string
EOF

if [ -n "$DEBI_HOSTNAME" ]; then
  echo "d-i netcfg/hostname string $DEBI_HOSTNAME" | $echo
fi

echo "d-i hw-detect/load_firmware boolean true" | $echo

if [ "$DEBI_SSH" = true ]; then
  $echo << EOF

# Network console

d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
EOF
  if [ -n "$DEBI_SSH_PASSWORD" ]; then
    echo "d-i network-console/password password $DEBI_SSH_PASSWORD" | $echo
    echo "d-i network-console/password-again password $DEBI_SSH_PASSWORD" | $echo
  fi
  if [ -n "$DEBI_SSH_KEYS" ]; then
    echo "d-i network-console/authorized_keys_url string $DEBI_SSH_KEYS" | $echo
  fi
  echo "d-i network-console/start select Continue" | $echo
fi

$echo << EOF

# Mirror settings

d-i mirror/country string manual
d-i mirror/protocol string $DEBI_PROTOCOL
d-i mirror/$DEBI_PROTOCOL/hostname string $DEBI_MIRROR
d-i mirror/$DEBI_PROTOCOL/directory string $DEBI_DIRECTORY
d-i mirror/$DEBI_PROTOCOL/proxy string
d-i mirror/suite string $DEBI_SUITE
d-i mirror/udeb/suite string $DEBI_SUITE

# Clock and time zone setup

d-i clock-setup/utc boolean true
d-i time/zone string $DEBI_TIMEZONE
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string $DEBI_NTP_SERVER
EOF

if [ "$DEBI_MANUAL" != true ]; then
  $echo << EOF

# Account setup

d-i passwd/root-login boolean false
d-i passwd/user-fullname string
d-i passwd/username string $DEBI_USERNAME
d-i passwd/user-password-crypted password $DEBI_PASSWORD

# Partitioning

d-i partman/default_filesystem string $DEBI_FILESYSTEM
d-i partman-auto/method string $DEBI_DISK_ENCRYPTION
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
EOF

  if [ "$DEBI_DISK_ENCRYPTION" = "regular" ]; then
    $echo << EOF
d-i partman-auto/expert_recipe string naive :: 0 1 -1 \$default_filesystem \$primary{ } \$bootable{ } method{ format } format{ } use_filesystem{ } \$default_filesystem{ } mountpoint{ / } .
d-i partman-auto/choose_recipe select naive
d-i partman-basicfilesystems/no_swap boolean false
EOF
  fi

  $echo << EOF
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/mount_style select uuid

# Base system installation

d-i base-installer/install-recommends boolean false

# Apt setup

d-i apt-setup/services-select multiselect updates, backports
d-i apt-setup/local0/repository string $DEBI_SECURITY_MIRROR $DEBI_SUITE/updates main
d-i apt-setup/local0/source boolean true

# Package selection

tasksel tasksel/first multiselect ssh-server
EOF

  if [ -n "$DEBI_INCLUDE" ]; then
    echo "d-i pkgsel/include string $DEBI_INCLUDE" | $echo
  fi

  $echo << EOF
d-i pkgsel/upgrade select $DEBI_UPGRADE
popularity-contest popularity-contest/participate boolean false

# Boot loader installation

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default

# Finishing up the installation

d-i finish-install/reboot_in_progress note
EOF

  if [ "$DEBI_POWEROFF" = true ]; then
    echo 'd-i debian-installer/exit/poweroff boolean true' | $echo
  fi
fi

echo2='cat'
if [ "$DEBI_DRY_RUN" != true ]; then
  $sudo wget "$DEBI_BASE_URL/linux" "$DEBI_BASE_URL/initrd.gz"
  $sudo gunzip initrd.gz
  echo preseed.cfg | $sudo cpio -H newc -o -A -F initrd
  $sudo gzip initrd
  echo2="$sudo tee -a $DEBI_GRUB_CONFIG"
fi

$echo2 << EOF
menuentry 'Debian Installer' --id debi {
insmod part_msdos
insmod ext2
set root='(hd0,msdos1)'
linux $DEBI_TARGET_PATH/linux
initrd $DEBI_TARGET_PATH/initrd.gz
}
EOF
