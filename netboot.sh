#!/bin/sh

set -ex

while [ $# -gt 0 ]; do
  case $1 in
    -c)
      COUNTRY=$2
      shift
      ;;
    -h)
      HOST=$2
      shift
      ;;
    -x)
      TRANSPORT=$2
      shift
      ;;
    -m)
      MIRROR=$2
      shift
      ;;
    -d)
      DIRECTORY=${2%/}
      shift
      ;;
    -r)
      SUITE=$2
      shift
      ;;
    -u)
      USERNAME=$2
      shift
      ;;
    -p)
      PASSWORD=$2
      shift
      ;;
    -z)
      TIMEZONE=$2
      shift
      ;;
    -t)
      NTPSERVER=$2
      shift
      ;;
    -s)
      SECURITY=$2
      shift
      ;;
    -g)
      UPGRADE=$2
      shift
      ;;
    -l)
      LINKED=true
      ;;
    *)
      echo "Illegal option $1"
      exit 1
  esac
  shift
done

case "$COUNTRY" in
  CN)
    TRANSPORT=${TRANSPORT:-https}
    MIRROR=${MIRROR:-chinanet.mirrors.ustc.edu.cn}
    TIMEZONE=${TIMEZONE:-Asia/Shanghai}
    NTPSERVER=${NTPSERVER:-ntp1.aliyun.com}
    LINKED=${LINKED:-true}
esac

COUNTRY=${COUNTRY:-US}
HOST=${HOST:-debian}
TRANSPORT=${TRANSPORT:-http}
MIRROR=${MIRROR:-deb.debian.org}
DIRECTORY=${DIRECTORY:-/debian}
ARCH=$(dpkg --print-architecture)
SUITE=${SUITE:-stable}
USERNAME=${USERNAME:-debian}
TIMEZONE=${TIMEZONE:-UTC}
NTPSERVER=${NTPSERVER:-pool.ntp.org}
UPGRADE=${UPGRADE:-full-upgrade}
LINKED=${LINKED:-false}

if [ -z "$PASSWORD" ]; then
  PASSWORD=$(mkpasswd -m sha-512)
else
  PASSWORD=$(mkpasswd -m sha-512 "$PASSWORD")
fi

if [ -z "$SECURITY" ]; then
  if $LINKED; then
    SECURITY=$TRANSPORT://$MIRROR${DIRECTORY%/*}/debian-security
  else
    SECURITY=http://security.debian.org/debian-security
  fi
fi

BOOT=/boot/debian-$SUITE
URL=$TRANSPORT://$MIRROR$DIRECTORY/dists/$SUITE/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH

update-grub
rm -fr "$BOOT"
mkdir -p "$BOOT"
cd "$BOOT"

cat >> preseed.cfg << EOF
# COUNTRY: 1
# HOST: 2
# TRANSPORT: 3
# MIRROR: 3
# DIRECTORY: 3
# SUITE: 3, 8
# USERNAME: 4
# PASSWORD: 4
# TIMEZONE: 5
# NTPSERVER: 5
# SECURITY: 8
# UPGRADE: 9

# 1. Localization: COUNTRY

d-i debian-installer/locale string en_US
d-i debian-installer/language string en
d-i debian-installer/country string {{-COUNTRY-}}
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# 2. Network configuration: HOST

d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain
d-i netcfg/hostname string {{-HOST-}}
d-i hw-detect/load_firmware boolean true

# 3. Mirror settings: TRANSPORT, MIRROR, DIRECTORY, SUITE

d-i mirror/country string manual
d-i mirror/protocol string {{-TRANSPORT-}}
d-i mirror/{{-TRANSPORT-}}/hostname string {{-MIRROR-}}
d-i mirror/{{-TRANSPORT-}}/directory string {{-DIRECTORY-}}
d-i mirror/{{-TRANSPORT-}}/proxy string
d-i mirror/suite string {{-SUITE-}}
d-i mirror/udeb/suite string {{-SUITE-}}

# 4. Account setup: USERNAME, PASSWORD

d-i passwd/root-login boolean false
d-i passwd/user-fullname string
d-i passwd/username string {{-USERNAME-}}
d-i passwd/user-password-crypted password {{-PASSWORD-}}

# 5. Clock and time zone setup: TIMEZONE, NTPSERVER

d-i clock-setup/utc boolean true
d-i time/zone string {{-TIMEZONE-}}
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string {{-NTPSERVER-}}

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
d-i pkgsel/upgrade select {{-UPGRADE-}}
popularity-contest popularity-contest/participate boolean false

# 10. Boot loader installation

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default
EOF

sed -i 's/{{-COUNTRY-}}/'"$COUNTRY"'/g' preseed.cfg
sed -i 's/{{-HOST-}}/'"$HOST"'/g' preseed.cfg
sed -i 's/{{-TRANSPORT-}}/'"$TRANSPORT"'/g' preseed.cfg
sed -i 's/{{-MIRROR-}}/'"$MIRROR"'/g' preseed.cfg
sed -i 's/{{-DIRECTORY-}}/'$(echo "$DIRECTORY" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-SUITE-}}/'"$SUITE"'/g' preseed.cfg
sed -i 's/{{-USERNAME-}}/'"$USERNAME"'/g' preseed.cfg
sed -i 's/{{-PASSWORD-}}/'$(echo "$PASSWORD" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-TIMEZONE-}}/'$(echo "$TIMEZONE" | sed 's/\//\\\//g')'/g' preseed.cfg
sed -i 's/{{-NTPSERVER-}}/'"$NTPSERVER"'/g' preseed.cfg
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
