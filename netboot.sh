#!/usr/bin/env bash

set -eu

_err() {
    printf 'Error: %s.\n' "$1" 1>&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

_late_command() {
    [ -z "$late_command" ] && late_command='true'
    late_command="$late_command; $1"
}

late_command=
preset=
ip=
netmask=
gateway=
dns=
hostname=
kernel_params=
installer_ssh=
installer_password=
authorized_keys_url=
mirror_protocol=
mirror_host=
mirror_directory=
suite=
skip_account_setup=
username=
password=
timezone=
ntp=
skip_partitioning=
disk=
partitioning_method=regular
filesystem=ext4
kernel=
security_repository=
install=
upgrade=
power_off=
architecture=
boot_partition=
dry_run=
bbr=
cleartext_password=
gpt=
initramfs=generic
install_recommends=true
efi=false

while [ $# -gt 0 ]; do
    case $1 in
        --preset)
            preset=$2
            shift
            ;;
        --ip)
            ip=$2
            shift
            ;;
        --netmask)
            netmask=$2
            shift
            ;;
        --gateway)
            gateway=$2
            shift
            ;;
        --dns)
            dns=$2
            shift
            ;;
        --hostname)
            hostname=$2
            shift
            ;;
        --eth)
            kernel_params=' net.ifnames=0 biosdevname=0'
            ;;
        --installer-password)
            installer_ssh=true
            installer_password=$2
            shift
            ;;
        --authorized-keys-url)
            installer_ssh=true
            authorized_keys_url=$2
            shift
            ;;
        --mirror-protocol)
            mirror_protocol=$2
            shift
            ;;
        --mirror-host)
            mirror_host=$2
            shift
            ;;
        --mirror-directory)
            mirror_directory=${2%/}
            shift
            ;;
        --suite)
            suite=$2
            shift
            ;;
        --skip-account-setup)
            skip_account_setup=true
            ;;
        --username)
            username=$2
            shift
            ;;
        --password)
            password=$2
            shift
            ;;
        --timezone)
            timezone=$2
            shift
            ;;
        --ntp)
            ntp=$2
            shift
            ;;
        --skip-partitioning)
            skip_partitioning=true
            ;;
        --disk)
            disk=$2
            shift
            ;;
        --partitioning-method)
            partitioning_method=$2
            shift
            ;;
        --filesystem)
            filesystem=$2
            shift
            ;;
        --kernel)
            kernel=$2
            shift
            ;;
        --security-repository)
            security_repository=$2
            shift
            ;;
        --install)
            install=$2
            shift
            ;;
        --upgrade)
            upgrade=$2
            shift
            ;;
        --power-off)
            power_off=true
            ;;
        --architecture)
            architecture=$2
            shift
            ;;
        --boot-partition)
            boot_partition=true
            ;;
        --dry-run)
            dry_run=true
            ;;
        --bbr)
            bbr=true
            ;;
        --gpt)
            gpt=true
            ;;
        --targeted-initramfs)
            initramfs=targeted
            ;;
        --no-install-recommends)
            install_recommends=false
            ;;
        --efi)
            efi=true
            ;;
        *)
            _err "Illegal option $1"
            exit 1
    esac
    shift
done

if [ -n "$preset" ]; then
    case "$preset" in
        china)
            dns=${dns:-223.5.5.5 223.6.6.6}
            mirror_protocol=${mirror_protocol:-https}
            mirror_host=${mirror_host:-mirrors.aliyun.com}
            ntp=${ntp:-ntp.aliyun.com}
            security_repository=${security_repository:-true}
            ;;
        cloud)
            mirror_protocol=${mirror_protocol:-https}
            mirror_host=${mirror_host:-deb.debian.org}
            security_repository=${security_repository:-true}
            ;;
        *)
            _err "No such preset $preset"
            exit 1
    esac
fi

suite=${suite:-buster}
installer="debian-$suite"
installer_directory="/boot/$installer"

save_preseed="cat"
if [ "$dry_run" != true ]; then
    user="$(id -un 2>/dev/null || true)"

    if [ "$user" != root ]; then
        _err 'root privilege is required'
        exit 1
    fi

    rm -rf "$installer_directory"
    mkdir -p "$installer_directory"
    cd "$installer_directory"
    save_preseed='tee -a preseed.cfg'
fi

$save_preseed << EOF
# Localization

d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network configuration

d-i netcfg/choose_interface select auto
EOF

dns=${dns:-8.8.8.8 8.8.4.4}

if [ -n "$ip" ]; then
    echo 'd-i netcfg/disable_autoconfig boolean true' | $save_preseed
    echo "d-i netcfg/get_ipaddress string $ip" | $save_preseed
    if [ -n "$netmask" ]; then
        echo "d-i netcfg/get_netmask string $netmask" | $save_preseed
    fi
    if [ -n "$gateway" ]; then
        echo "d-i netcfg/get_gateway string $gateway" | $save_preseed
    fi
    if [ -n "$dns" ]; then
        echo "d-i netcfg/get_nameservers string $dns" | $save_preseed
    fi
    echo 'd-i netcfg/confirm_static boolean true' | $save_preseed
fi

$save_preseed << EOF
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string
EOF

if [ -n "$hostname" ]; then
    echo "d-i netcfg/hostname string $hostname" | $save_preseed
fi

echo 'd-i hw-detect/load_firmware boolean true' | $save_preseed

if [ "$installer_ssh" = true ]; then
    $save_preseed << EOF

# Network console

d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
EOF
    if [ -n "$authorized_keys_url" ]; then
        _late_command 'sed -ri "s/^#?PasswordAuthentication .+/PasswordAuthentication no/" /etc/ssh/sshd_config'
        $save_preseed << EOF
d-i network-console/password-disabled boolean true
d-i network-console/authorized_keys_url string $authorized_keys_url
EOF
    elif [ -n "$installer_password" ]; then
        $save_preseed << EOF
d-i network-console/password-disabled boolean false
d-i network-console/password password $installer_password
d-i network-console/password-again password $installer_password
EOF
    fi
    echo 'd-i network-console/start select Continue' | $save_preseed
fi

mirror_protocol=${mirror_protocol:-http}
mirror_host=${mirror_host:-deb.debian.org}
mirror_directory=${mirror_directory:-/debian}

$save_preseed << EOF

# Mirror settings

d-i mirror/country string manual
d-i mirror/protocol string $mirror_protocol
d-i mirror/$mirror_protocol/hostname string $mirror_host
d-i mirror/$mirror_protocol/directory string $mirror_directory
d-i mirror/$mirror_protocol/proxy string
d-i mirror/suite string $suite
d-i mirror/udeb/suite string $suite
EOF

if [ "$skip_account_setup" != true ]; then
    username=${username:-debian}

    if command_exists mkpasswd; then
        if [ -z "$password" ]; then
            password="$(mkpasswd -m sha-512)"
        else
            password="$(mkpasswd -m sha-512 "$password")"
        fi
    elif command_exists busybox && busybox mkpasswd --help >/dev/null 2>&1; then
        if [ -z "$password" ]; then
            read -rs -p 'Password: ' password
        fi
        password="$(busybox mkpasswd -m sha512 "$password")"
    elif command_exists python3; then
        if [ -z "$password" ]; then
            password="$(python3 -c 'import crypt, getpass; print(crypt.crypt(getpass.getpass(), crypt.mksalt(crypt.METHOD_SHA512)))')"
        else
            password="$(python3 -c "import crypt; print(crypt.crypt(\"$password\", crypt.mksalt(crypt.METHOD_SHA512)))")"
        fi
    else
        cleartext_password=true
        if [ -z "$password" ]; then
            read -rs -p 'Password: ' password
        fi
    fi

    $save_preseed << EOF

# Account setup

EOF

    if [ "$username" = root ]; then
        if [ -z "$authorized_keys_url" ]; then
            _late_command 'sed -ri "s/^#?PermitRootLogin .+/PermitRootLogin yes/" /etc/ssh/sshd_config'
        else
            _late_command "mkdir -pm 700 /root/.ssh && busybox wget -qO /root/.ssh/authorized_keys \"$authorized_keys_url\""
        fi
        $save_preseed << EOF
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
EOF
        if [ "$cleartext_password" = true ]; then
            $save_preseed << EOF
d-i passwd/root-password password $password
d-i passwd/root-password-again password $password
EOF
        else
            echo "d-i passwd/root-password-crypted password $password" | $save_preseed
        fi
    else
        _late_command 'sed -ri "s/^#?PermitRootLogin .+/PermitRootLogin no/" /etc/ssh/sshd_config'
        if [ -n "$authorized_keys_url" ]; then
            _late_command "sudo -u $username mkdir -pm 700 /home/$username/.ssh && sudo -u $username busybox wget -qO /home/$username/.ssh/authorized_keys \"$authorized_keys_url\""
        fi
        $save_preseed << EOF
d-i passwd/root-login boolean false
d-i passwd/make-user boolean true
d-i passwd/user-fullname string
d-i passwd/username string $username
EOF
        if [ "$cleartext_password" = true ]; then
            $save_preseed << EOF
d-i passwd/user-password password $password
d-i passwd/user-password-again password $password
EOF
        else
            echo "d-i passwd/user-password-crypted password $password" | $save_preseed
        fi
    fi
fi

timezone=${timezone:-UTC}
ntp=${ntp:-0.debian.pool.ntp.org}

$save_preseed << EOF

# Clock and time zone setup

d-i time/zone string $timezone
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string $ntp
EOF

if [ "$skip_partitioning" != true ]; then
    $save_preseed << 'EOF'

# Partitioning

EOF
    if [ -n "$disk" ]; then
        echo "d-i partman-auto/disk string $disk" | $save_preseed
    fi

    echo "d-i partman-auto/method string $partitioning_method" | $save_preseed

    if [ "$partitioning_method" = regular ]; then
        if [ "$gpt" = true ]; then
            $save_preseed << 'EOF'
d-i partman-partitioning/default_label string gpt
#d-i partman-partitioning/choose_label select gpt
EOF
        fi
        echo "d-i partman/default_filesystem string $filesystem" | $save_preseed
        $save_preseed << 'EOF'
d-i partman-auto/expert_recipe string \
    naive :: \
        1 1 1 free \
	        $iflabel{ gpt } \
	        $reusemethod{ } \
	        method{ biosgrub } \
        . \
EOF
        if [ "$efi" = true ]; then
            $save_preseed << 'EOF'
        512 512 512 free \
            $iflabel{ gpt } \
            $reusemethod{ } \
            method{ efi } \
            format{ } \
        . \
EOF
        fi
        $save_preseed << 'EOF'
        1536 1536 -1 $default_filesystem \
            method{ format } \
            format{ } \
            use_filesystem{ } \
            $default_filesystem{ } \
            mountpoint{ / } \
        .
EOF
        echo "d-i partman-auto/choose_recipe select naive" | $save_preseed
    fi
    $save_preseed << 'EOF'
d-i partman-basicfilesystems/no_swap boolean false
#d-i partman-partitioning/confirm_new_label boolean true
#d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
#d-i partman/confirm boolean true
#d-i partman/confirm_nooverwrite boolean true
EOF
fi

$save_preseed << EOF

# Base system installation

d-i base-installer/install-recommends boolean $install_recommends
d-i base-installer/initramfs-tools/driver-policy select $initramfs
EOF

if [ -n "$kernel" ]; then
    echo "d-i base-installer/kernel/image string $kernel" | $save_preseed
fi

if [ -z "$security_repository" ]; then
    security_repository=http://security.debian.org/debian-security
else
    if [ "$security_repository" = true ]; then
        security_repository=$mirror_protocol://$mirror_host${mirror_directory%/*}/debian-security
    fi
fi

$save_preseed << EOF

# Apt setup

d-i apt-setup/services-select multiselect updates, backports
d-i apt-setup/local0/repository string $security_repository $suite/updates main
d-i apt-setup/local0/source boolean true
EOF

upgrade=${upgrade:-full-upgrade}

$save_preseed << EOF

# Package selection

tasksel tasksel/first multiselect ssh-server
EOF

if [ -n "$install" ]; then
    echo "d-i pkgsel/include string $install" | $save_preseed
fi

$save_preseed << EOF
d-i pkgsel/upgrade select $upgrade
popularity-contest popularity-contest/participate boolean false

# Boot loader installation

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default
EOF

if [ -n "$kernel_params" ]; then
    echo "d-i debian-installer/add-kernel-opts string$kernel_params" | $save_preseed
fi

$save_preseed << EOF

# Finishing up the installation

d-i finish-install/reboot_in_progress note
EOF

if [ "$bbr" = true ]; then
    _late_command '{ echo "net.core.default_qdisc=fq"; echo "net.ipv4.tcp_congestion_control=bbr"; } > /etc/sysctl.d/bbr.conf'
fi

if [ -n "$late_command" ]; then
    echo "d-i preseed/late_command string in-target sh -c '$late_command'" | $save_preseed
fi

if [ "$power_off" = true ]; then
    echo 'd-i debian-installer/exit/poweroff boolean true' | $save_preseed
fi

save_grub_cfg="cat"
if [ "$dry_run" != true ]; then
    if [ -z "$architecture" ]; then
        if command_exists dpkg; then
            architecture="$(dpkg --print-architecture)"
        else
            architecture=amd64
        fi
    fi

    base_url="$mirror_protocol://$mirror_host$mirror_directory/dists/$suite/main/installer-$architecture/current/images/netboot/debian-installer/$architecture"

    if command_exists wget; then
        wget "$base_url/linux" "$base_url/initrd.gz"
    elif command_exists curl; then
        curl -O "$base_url/linux" -O "$base_url/initrd.gz"
    elif command_exists busybox; then
        busybox wget "$base_url/linux" "$base_url/initrd.gz"
    else
        _err 'wget/curl/busybox is required to download files'
        exit 1
    fi

    gunzip initrd.gz
    echo preseed.cfg | cpio -H newc -o -A -F initrd
    gzip initrd

    if command_exists update-grub; then
        grub_cfg=/boot/grub/grub.cfg
        update-grub
    elif command_exists grub2-mkconfig; then
        grub_cfg=/boot/grub2/grub.cfg
        grub2-mkconfig -o "$grub_cfg"
    else
        _err 'update-grub/grub2-mkconfig command not found'
        exit 1
    fi

    save_grub_cfg="tee -a $grub_cfg"
fi

if [ "$boot_partition" = true ]; then
    boot_directory=/
else
    boot_directory=/boot/
fi

installer_directory="$boot_directory$installer"

$save_grub_cfg << EOF
menuentry 'Debian Installer' --id debi {
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    linux $installer_directory/linux$kernel_params
    initrd $installer_directory/initrd.gz
}
EOF
