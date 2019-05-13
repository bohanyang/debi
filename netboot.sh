#!/usr/bin/env sh

# Copyright 2018-present Bohan Yang (Brent)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

echo_stderr() {
    echo "$@" 1>&2
}

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

read_secret()
{
    stty -echo
    trap 'stty echo' EXIT
    read "$@"
    stty echo
    trap - EXIT
    echo
}

while [ $# -gt 0 ]; do
    case $1 in
        --preset)
            DEBI_PRESET=$2
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
        --ns)
            DEBI_NS=$2
            shift
            ;;
        --hostname)
            DEBI_HOSTNAME=$2
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
        --skip-user)
            DEBI_SKIP_USER=true
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
        --ntp)
            DEBI_NTP=$2
            shift
            ;;
        --skip-part)
            DEBI_SKIP_PART=true
            ;;
        --disk)
            DEBI_DISK=$2
            shift
            ;;
        --part)
            DEBI_PART=$2
            shift
            ;;
        --fs)
            DEBI_FS=$2
            shift
            ;;
        --security)
            DEBI_SECURITY=$2
            shift
            ;;
        --install)
            DEBI_INSTALL=$2
            shift
            ;;
        --upgrade)
            DEBI_UPGRADE=$2
            shift
            ;;
        --poweroff)
            DEBI_POWEROFF=true
            ;;
        --arch)
            DEBI_ARCH=$2
            shift
            ;;
        --boot-partition)
            DEBI_BOOT_PARTITION=true
            ;;
        --gpt)
            DEBI_PARTITION_TYPE=gpt
            ;;
        --dry-run)
            DEBI_DRY_RUN=true
            ;;
        *)
            echo_stderr "Error: Illegal option $1"
            exit 1
    esac
    shift
done

case "$DEBI_PRESET" in
    china)
        DEBI_NS=${DEBI_NS:-156.154.70.5 156.154.71.5}
        DEBI_PROTOCOL=${DEBI_PROTOCOL:-https}
        DEBI_MIRROR=${DEBI_MIRROR:-chinanet.mirrors.ustc.edu.cn}
        DEBI_TIMEZONE=${DEBI_TIMEZONE:-Asia/Shanghai}
        DEBI_NTP=${DEBI_NTP:-cn.ntp.org.cn}
        DEBI_SECURITY=${DEBI_SECURITY:-true}
        ;;
    cloud)
        DEBI_PROTOCOL=${DEBI_PROTOCOL:-https}
        DEBI_MIRROR=${DEBI_MIRROR:-cdn-aws.deb.debian.org}
        DEBI_NTP=${DEBI_NTP:-time.google.com}
        DEBI_SECURITY=${DEBI_SECURITY:-true}
    *)
        echo_stderr "Error: No such preset $DEBI_PRESET"
        exit 1
esac

DEBI_SUITE=${DEBI_SUITE:-stretch}

save_preseed=cat
if [ "$DEBI_DRY_RUN" != true ]; then
    user="$(id -un 2>/dev/null || true)"

    if [ "$user" != root ]; then
        echo_stderr 'Error: Require root.'
        exit 1
    fi

    DEBI_NEW="debian-$DEBI_SUITE"
    DEBI_NEW_DIR="/boot/$DEBI_NEW"

    rm -rf "$DEBI_NEW_DIR"
    mkdir -p "$DEBI_NEW_DIR"
    save_preseed="tee -a $DEBI_NEW_DIR/preseed.cfg"
fi

$save_preseed << EOF
# Localization

d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network configuration

d-i netcfg/choose_interface select auto
EOF

DEBI_NS=${DEBI_NS:-1.1.1.1 1.0.0.1}

if [ -n "$DEBI_IP" ]; then
    echo 'd-i netcfg/disable_autoconfig boolean true' | $save_preseed
    echo "d-i netcfg/get_ipaddress string $DEBI_IP" | $save_preseed
    if [ -n "$DEBI_NETMASK" ]; then
        echo "d-i netcfg/get_netmask string $DEBI_NETMASK" | $save_preseed
    fi
    if [ -n "$DEBI_GATEWAY" ]; then
        echo "d-i netcfg/get_gateway string $DEBI_GATEWAY" | $save_preseed
    fi
    if [ -n "$DEBI_NS" ]; then
        echo "d-i netcfg/get_nameservers string $DEBI_NS" | $save_preseed
    fi
    echo 'd-i netcfg/confirm_static boolean true' | $save_preseed
fi

$save_preseed << EOF
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string
EOF

if [ -n "$DEBI_HOSTNAME" ]; then
    echo "d-i netcfg/hostname string $DEBI_HOSTNAME" | $save_preseed
fi

echo 'd-i hw-detect/load_firmware boolean true' | $save_preseed

if [ "$DEBI_SSH" = true ]; then
    $save_preseed << EOF

# Network console

d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
EOF
    if [ -n "$DEBI_SSH_PASSWORD" ]; then
        echo "d-i network-console/password password $DEBI_SSH_PASSWORD" | $save_preseed
        echo "d-i network-console/password-again password $DEBI_SSH_PASSWORD" | $save_preseed
    fi
    if [ -n "$DEBI_SSH_KEYS" ]; then
        echo "d-i network-console/authorized_keys_url string $DEBI_SSH_KEYS" | $save_preseed
    fi
    echo 'd-i network-console/start select Continue' | $save_preseed
fi

DEBI_PROTOCOL=${DEBI_PROTOCOL:-http}
DEBI_MIRROR=${DEBI_MIRROR:-deb.debian.org}
DEBI_DIRECTORY=${DEBI_DIRECTORY:-/debian}

$save_preseed << EOF

# Mirror settings

d-i mirror/country string manual
d-i mirror/protocol string $DEBI_PROTOCOL
d-i mirror/$DEBI_PROTOCOL/hostname string $DEBI_MIRROR
d-i mirror/$DEBI_PROTOCOL/directory string $DEBI_DIRECTORY
d-i mirror/$DEBI_PROTOCOL/proxy string
d-i mirror/suite string $DEBI_SUITE
d-i mirror/udeb/suite string $DEBI_SUITE
EOF

if [ "$DEBI_SKIP_USER" != true ]; then
    DEBI_USERNAME=${DEBI_USERNAME:-debian}

    if command_exists mkpasswd; then
        if [ -z "$DEBI_PASSWORD" ]; then
            DEBI_PASSWORD="$(mkpasswd -m sha-512)"
        else
            DEBI_PASSWORD="$(mkpasswd -m sha-512 "$DEBI_PASSWORD")"
        fi
    elif command_exists python3; then
        if [ -z "$DEBI_PASSWORD" ]; then
            DEBI_PASSWORD="$(python3 -c 'import crypt, getpass; print(crypt.crypt(getpass.getpass(), crypt.mksalt(crypt.METHOD_SHA512)))')"
        else
            DEBI_PASSWORD="$(python3 -c "import crypt; print(crypt.crypt(\"$DEBI_PASSWORD\", crypt.mksalt(crypt.METHOD_SHA512)))")"
        fi
    else
        DEBI_CLEARTEXT=true
        if [ -z "$DEBI_PASSWORD" ]; then
            printf 'Password: '
            read_secret DEBI_PASSWORD
        fi
    fi

    $save_preseed << EOF

# Account setup

EOF

    if [ "$DEBI_USERNAME" = root ]; then
        echo 'd-i passwd/make-user boolean false' | $save_preseed
        if [ "$DEBI_CLEARTEXT" = true ]; then
            $save_preseed << EOF
d-i passwd/root-password password $DEBI_PASSWORD
d-i passwd/root-password-again password $DEBI_PASSWORD
EOF
        else
            echo "d-i passwd/root-password-crypted password $DEBI_PASSWORD" | $save_preseed
        fi
    else
        $save_preseed << EOF
d-i passwd/root-login boolean false
d-i passwd/user-fullname string
d-i passwd/username string $DEBI_USERNAME
EOF
        if [ "$DEBI_CLEARTEXT" = true ]; then
            $save_preseed << EOF
d-i passwd/user-password password $DEBI_PASSWORD
d-i passwd/user-password-again password $DEBI_PASSWORD
EOF
        else
            echo "d-i passwd/user-password-crypted password $DEBI_PASSWORD"
        fi
    fi
fi

DEBI_TIMEZONE=${DEBI_TIMEZONE:-UTC}
DEBI_NTP=${DEBI_NTP:-pool.ntp.org}

$save_preseed << EOF

# Clock and time zone setup

d-i clock-setup/utc boolean true
d-i time/zone string $DEBI_TIMEZONE
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string $DEBI_NTP
EOF

if [ "$DEBI_SKIP_PART" != true ]; then
    DEBI_FS=${DEBI_FS:-ext4}
    DEBI_PART=${DEBI_PART:-regular}

    $save_preseed << EOF

# Partitioning

EOF

    if [ -n "$DEBI_DISK" ]; then
        echo "d-i partman-auto/disk string $DEBI_DISK" | $save_preseed
    fi

    $save_preseed << EOF
d-i partman-auto/method string $DEBI_PART
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
EOF

    if [ "$DEBI_PART" = "regular" ]; then
        $save_preseed << EOF
d-i partman/default_filesystem string $DEBI_FS
d-i partman-auto/expert_recipe string naive :: 0 1 -1 \$default_filesystem \$primary{ } \$bootable{ } method{ format } format{ } use_filesystem{ } \$default_filesystem{ } mountpoint{ / } .
d-i partman-auto/choose_recipe select naive
d-i partman-basicfilesystems/no_swap boolean false
EOF
    fi

    $save_preseed << EOF
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/mount_style select uuid
EOF
fi

$save_preseed << EOF

# Base system installation

d-i base-installer/install-recommends boolean false
EOF

if [ -z "$DEBI_SECURITY" ]; then
    DEBI_SECURITY=http://security.debian.org/debian-security
else
    if [ "$DEBI_SECURITY" = true ]; then
        DEBI_SECURITY=$DEBI_PROTOCOL://$DEBI_MIRROR${DEBI_DIRECTORY%/*}/debian-security
    fi
fi

$save_preseed << EOF

# Apt setup

d-i apt-setup/services-select multiselect updates, backports
d-i apt-setup/local0/repository string $DEBI_SECURITY $DEBI_SUITE/updates main
d-i apt-setup/local0/source boolean true
EOF

DEBI_UPGRADE=${DEBI_UPGRADE:-full-upgrade}

$save_preseed << EOF

# Package selection

tasksel tasksel/first multiselect ssh-server
EOF

if [ -n "$DEBI_INSTALL" ]; then
    echo "d-i pkgsel/include string $DEBI_INSTALL" | $save_preseed
fi

$save_preseed << EOF
d-i pkgsel/upgrade select $DEBI_UPGRADE
popularity-contest popularity-contest/participate boolean false

# Boot loader installation

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default

# Finishing up the installation

d-i finish-install/reboot_in_progress note
EOF

if [ "$DEBI_POWEROFF" = true ]; then
    echo 'd-i debian-installer/exit/poweroff boolean true' | $save_preseed
fi

save_grubcfg=cat
if [ "$DEBI_DRY_RUN" != true ]; then
    if [ -z "$DEBI_ARCH" ]; then
        if command_exists dpkg; then
            DEBI_ARCH="$(dpkg --print-architecture)"
        else
            DEBI_ARCH=amd64
        fi
    fi

    DEBI_BASE_URL="$DEBI_PROTOCOL://$DEBI_MIRROR$DEBI_DIRECTORY/dists/$DEBI_SUITE/main/installer-$DEBI_ARCH/current/images/netboot/debian-installer/$DEBI_ARCH"

    if command_exists wget; then
        wget -P "$DEBI_NEW_DIR" "$DEBI_BASE_URL/linux" "$DEBI_BASE_URL/initrd.gz"
    elif command_exists curl; then
        curl "$DEBI_BASE_URL/linux" -o "$DEBI_NEW_DIR/linux" "$DEBI_BASE_URL/initrd.gz" -o "$DEBI_NEW_DIR/initrd.gz"
    else
        echo_stderr 'Error: wget/curl not found.'
        exit 1
    fi

    gunzip initrd.gz
    echo preseed.cfg | cpio -H newc -o -A -F initrd
    gzip initrd

    if command_exists update-grub; then
        DEBI_GRUBCFG=/boot/grub/grub.cfg
        update-grub
    elif command_exists grub2-mkconfig; then
        DEBI_GRUBCFG=/boot/grub2/grub.cfg
        grub2-mkconfig -o "$DEBI_GRUBCFG"
    else
        echo_stderr 'Error: Command update-grub/grub2-mkconfig not found.'
        exit 1
    fi

    save_grubcfg="tee -a $DEBI_GRUBCFG"
fi

if [ "$DEBI_BOOT_PARTITION" = true ]; then
    DEBI_BOOT_DIR=/
else
    DEBI_BOOT_DIR=/boot/
fi

DEBI_NEW_DIR="$DEBI_BOOT_DIR$DEBI_NEW"
DEBI_PARTITION_TYPE=${DEBI_PARTITION_TYPE:-msdos}

$save_grubcfg << EOF
menuentry 'Debian Installer' --id debi {
insmod part_$DEBI_PARTITION_TYPE
insmod ext2
set root='(hd0,${DEBI_PARTITION_TYPE}1)'
linux $DEBI_NEW_DIR/linux
initrd $DEBI_NEW_DIR/initrd.gz
}
EOF
