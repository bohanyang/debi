#!/bin/sh
# shellcheck shell=dash

set -eu

err() {
    echo "Error: $1." 1>&2
    exit 1
}

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

in_target=
late_command() {
    local cmd=
    for arg in "$@"; do
        cmd="$cmd $arg"
    done
    if [ -n "$cmd" ]; then
        [ -z "$in_target" ] && in_target='true'
        in_target="$in_target;$cmd"
    fi
}

in_target_backup() {
    late_command "if [ ! -e \"$1.backup\" ]; then cp \"$1\" \"$1.backup\"; fi"
}

sshd_conf() {
    [ -z ${backed_sshd+1} ] && in_target_backup /etc/ssh/sshd_config
    backed_sshd=
    late_command sed -Ei \""s/^#?$1 .+/$1 $2/"\" /etc/ssh/sshd_config
}

prompt_password() {
    stty -echo
    echo -n "Choose a password for the new user $username: " > /dev/tty
    read -r password < /dev/tty
    stty echo
    echo > /dev/tty
}

ip=
netmask=
gateway=
dns='8.8.8.8 8.8.4.4'
hostname=
network_console=false
suite=buster
mirror_protocol=http
mirror_host=deb.debian.org
mirror_directory=/debian
security_repository=http://security.debian.org/debian-security
skip_account_setup=false
username=debian
password=
authorized_keys_url=
sudo_with_password=false
timezone=UTC
ntp=0.debian.pool.ntp.org
skip_partitioning=false
disk=
force_gpt=true
efi=
filesystem=ext4
kernel=
install_recommends=true
install='ca-certificates libpam-systemd'
upgrade=
kernel_params=
bbr=false
hold=false
power_off=false
architecture=
boot_directory=/boot/
firmware=false
force_efi_extra_removable=false
grub_timeout=5
dry_run=false

while [ $# -gt 0 ]; do
    case $1 in
        --cdn|--aws)
            mirror_protocol=https
            [ "$1" = '--aws' ] && mirror_host=cdn-aws.deb.debian.org
            security_repository=mirror
            ;;
        --china)
            dns='223.5.5.5 223.6.6.6'
            mirror_protocol=https
            mirror_host=mirrors.aliyun.com
            ntp=ntp.aliyun.com
            security_repository=mirror
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
        --network-console)
            network_console=true
            ;;
        --suite)
            suite=$2
            shift
            ;;
        --mirror-protocol)
            mirror_protocol=$2
            shift
            ;;
        --https)
            mirror_protocol=https
            ;;
        --mirror-host)
            mirror_host=$2
            shift
            ;;
        --mirror-directory)
            mirror_directory=${2%/}
            shift
            ;;
        --security-repository)
            security_repository=$2
            shift
            ;;
        --skip-account-setup)
            skip_account_setup=true
            ;;
        --user|--username)
            username=$2
            shift
            ;;
        --password)
            password=$2
            shift
            ;;
        --authorized-keys-url)
            authorized_keys_url=$2
            shift
            ;;
        --sudo-with-password)
            sudo_with_password=true
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
        --no-force-gpt)
            force_gpt=false
            ;;
        --bios)
            efi=false
            ;;
        --efi)
            efi=true
            ;;
        --filesystem)
            filesystem=$2
            shift
            ;;
        --kernel)
            kernel=$2
            shift
            ;;
        --cloud-kernel)
            kernel=linux-image-cloud-amd64
            ;;
        --no-install-recommends)
            install_recommends=false
            ;;
        --install)
            install=$2
            shift
            ;;
        --no-upgrade)
            upgrade=none
            ;;
        --safe-upgrade)
            upgrade=safe-upgrade
            ;;
        --full-upgrade)
            upgrade=full-upgrade
            ;;
        --eth)
            kernel_params=' net.ifnames=0 biosdevname=0'
            ;;
        --bbr)
            bbr=true
            ;;
        --hold)
            hold=true
            ;;
        --power-off)
            power_off=true
            ;;
        --architecture)
            architecture=$2
            shift
            ;;
        --boot-partition)
            boot_directory=/
            ;;
        --firmware)
            firmware=true
            ;;
        --force-efi-extra-removable)
            force_efi_extra_removable=true
            ;;
        --grub-timeout)
            grub_timeout=$2
            shift
            ;;
        --dry-run)
            dry_run=true
            ;;
        *)
            err "Illegal option $1"
    esac
    shift
done

installer="debian-$suite"
installer_directory="/boot/$installer"

save_preseed='cat'
if [ "$dry_run" != true ]; then
    [ "$(id -u)" -ne 0 ] && err 'root privilege is required'
    rm -rf "$installer_directory"
    mkdir -p "$installer_directory/initrd"
    cd "$installer_directory"
    save_preseed='tee -a initrd/preseed.cfg'
fi

$save_preseed << 'EOF'
# Localization

d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network configuration

d-i netcfg/choose_interface select auto
EOF

if [ -n "$ip" ]; then
    echo 'd-i netcfg/disable_autoconfig boolean true' | $save_preseed
    echo "d-i netcfg/get_ipaddress string $ip" | $save_preseed
    [ -n "$netmask" ] && echo "d-i netcfg/get_netmask string $netmask" | $save_preseed
    [ -n "$gateway" ] && echo "d-i netcfg/get_gateway string $gateway" | $save_preseed
    [ -n "$dns" ] && echo "d-i netcfg/get_nameservers string $dns" | $save_preseed
    echo 'd-i netcfg/confirm_static boolean true' | $save_preseed
fi

$save_preseed << 'EOF'
d-i netcfg/get_hostname string debian
d-i netcfg/get_domain string
EOF

if [ -n "$hostname" ]; then
    echo "d-i netcfg/hostname string $hostname" | $save_preseed
fi

echo 'd-i hw-detect/load_firmware boolean true' | $save_preseed

while [ -z "$password" ]; do
    prompt_password
done

if [ "$network_console" = true ]; then
    $save_preseed << EOF

# Network console

d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
d-i network-console/password password $password
d-i network-console/password-again password $password
EOF
    [ -n "$authorized_keys_url" ] && echo "d-i network-console/authorized_keys_url string $authorized_keys_url" | $save_preseed
    echo 'd-i network-console/start select Continue' | $save_preseed
fi

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
    password_hash=
    if command_exists mkpasswd; then
        password_hash=$(mkpasswd -m sha-512 "$password")
    elif command_exists busybox && busybox mkpasswd --help >/dev/null 2>&1; then
        password_hash=$(busybox mkpasswd -m sha512 "$password")
    elif command_exists python3; then
        password_hash=$(python3 -c 'import crypt, sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))' "$password")
    elif command_exists python; then
        password_hash=$(python -c 'import crypt, sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))' "$password" 2> /dev/null) || password_hash=
    fi

    $save_preseed << 'EOF'

# Account setup

EOF
    if [ -n "$authorized_keys_url" ]; then
        sshd_conf PasswordAuthentication no
    fi

    if [ "$username" = root ]; then
        if [ -z "$authorized_keys_url" ]; then
            sshd_conf PermitRootLogin yes
        else
            late_command "mkdir -m 0700 -p ~root/.ssh && busybox wget -O - \"$authorized_keys_url\" >> ~root/.ssh/authorized_keys"
        fi

        $save_preseed << 'EOF'
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
EOF

        if [ -z "$password_hash" ]; then
            $save_preseed << EOF
d-i passwd/root-password password $password
d-i passwd/root-password-again password $password
EOF
        else
            echo "d-i passwd/root-password-crypted password $password_hash" | $save_preseed
        fi
    else
        sshd_conf PermitRootLogin no

        if [ -n "$authorized_keys_url" ]; then
            late_command "sudo -u $username mkdir -m 0700 -p ~$username/.ssh && busybox wget -O - \"$authorized_keys_url\" | sudo -u $username tee -a ~$username/.ssh/authorized_keys"
        fi

        if [ "$sudo_with_password" = false ]; then
            late_command "echo \"$username ALL=(ALL:ALL) NOPASSWD:ALL\" > \"/etc/sudoers.d/90-user-$username\""
        fi

        $save_preseed << EOF
d-i passwd/root-login boolean false
d-i passwd/make-user boolean true
d-i passwd/user-fullname string
d-i passwd/username string $username
EOF

        if [ -z "$password_hash" ]; then
            $save_preseed << EOF
d-i passwd/user-password password $password
d-i passwd/user-password-again password $password
EOF
        else
            echo "d-i passwd/user-password-crypted password $password_hash" | $save_preseed
        fi
    fi
fi

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

d-i partman-auto/method string regular
EOF
    [ -n "$disk" ] && echo "d-i partman-auto/disk string $disk" | $save_preseed

    [ "$force_gpt" = true ] && echo 'd-i partman-partitioning/default_label string gpt' | $save_preseed

    echo "d-i partman/default_filesystem string $filesystem" | $save_preseed

    if [ -z "$efi" ]; then
        efi=false
        [ -d /sys/firmware/efi ] && efi=true
    fi

    $save_preseed << 'EOF'
d-i partman-auto/expert_recipe string \
    naive :: \
EOF
    if [ "$efi" = true ]; then
        $save_preseed << 'EOF'
        538 538 1075 free \
            $iflabel{ gpt } \
            $reusemethod{ } \
            method{ efi } \
            format{ } \
        . \
EOF
    else
        $save_preseed << 'EOF'
        1 1 1 free \
            $iflabel{ gpt } \
            $reusemethod{ } \
            method{ biosgrub } \
        . \
EOF
    fi

    $save_preseed << 'EOF'
        2149 2150 -1 $default_filesystem \
            method{ format } \
            format{ } \
            use_filesystem{ } \
            $default_filesystem{ } \
            mountpoint{ / } \
        .
EOF
    echo "d-i partman-auto/choose_recipe select naive" | $save_preseed

    $save_preseed << 'EOF'
d-i partman-basicfilesystems/no_swap boolean false
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
EOF

fi

$save_preseed << 'EOF'

# Base system installation

EOF

[ "$install_recommends" = false ] && echo "d-i base-installer/install-recommends boolean $install_recommends" | $save_preseed
[ -n "$kernel" ] && echo "d-i base-installer/kernel/image string $kernel" | $save_preseed

[ "$security_repository" = mirror ] && security_repository=$mirror_protocol://$mirror_host${mirror_directory%/*}/debian-security

$save_preseed << EOF

# Apt setup

d-i apt-setup/services-select multiselect updates, backports
d-i apt-setup/local0/repository string $security_repository $suite/updates main
d-i apt-setup/local0/source boolean true
EOF

$save_preseed << 'EOF'

# Package selection

tasksel tasksel/first multiselect ssh-server
EOF

[ -n "$install" ] && echo "d-i pkgsel/include string $install" | $save_preseed
[ -n "$upgrade" ] && echo "d-i pkgsel/upgrade select $upgrade" | $save_preseed

$save_preseed << 'EOF'
popularity-contest popularity-contest/participate boolean false

# Boot loader installation

d-i grub-installer/bootdev string default
EOF

[ "$force_efi_extra_removable" = true ] && echo "d-i grub-installer/force-efi-extra-removable boolean true" | $save_preseed
[ -n "$kernel_params" ] && echo "d-i debian-installer/add-kernel-opts string$kernel_params" | $save_preseed

$save_preseed << 'EOF'

# Finishing up the installation

EOF

[ "$hold" != true ] && echo 'd-i finish-install/reboot_in_progress note' | $save_preseed

[ "$bbr" = true ] && late_command '{ echo "net.core.default_qdisc=fq"; echo "net.ipv4.tcp_congestion_control=bbr"; } > /etc/sysctl.d/bbr.conf'

[ -n "$in_target" ] && echo "d-i preseed/late_command string in-target dash -c '$in_target'" | $save_preseed

[ "$power_off" = true ] && echo 'd-i debian-installer/exit/poweroff boolean true' | $save_preseed

save_grub_cfg='cat'
if [ "$dry_run" != true ]; then
    if [ -z "$architecture" ]; then
        architecture=amd64
        command_exists dpkg && architecture=$(dpkg --print-architecture)
    fi

    base_url="$mirror_protocol://$mirror_host$mirror_directory/dists/$suite/main/installer-$architecture/current/images/netboot/debian-installer/$architecture"
    firmware_url="https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/$suite/current/firmware.cpio.gz"

    if command_exists wget; then
        wget "$base_url/linux" "$base_url/initrd.gz"
        [ "$firmware" = true ] && wget "$firmware_url"
    elif command_exists curl; then
        curl -f -L -O "$base_url/linux" -O "$base_url/initrd.gz"
        [ "$firmware" = true ] && curl -f -L -O "$firmware_url"
    elif command_exists busybox && busybox wget --help >/dev/null 2>&1; then
        busybox wget "$base_url/linux" "$base_url/initrd.gz"
        [ "$firmware" = true ] && busybox wget "$firmware_url"
    else
        err 'Could not find "wget" or "curl" or "busybox wget" command to download files'
    fi

    cd initrd

    gzip -d -c ../initrd.gz | cpio -i -d --no-absolute-filenames
    [ "$firmware" = true ] && gzip -d -c ../firmware.cpio.gz | cpio -i -d --no-absolute-filenames
    find . | cpio -o -H newc | gzip -9 > ../initrd.gz

    cd ..

    mkdir -p /etc/default/grub.d
    tee /etc/default/grub.d/zz-debi.cfg 1>&2 << EOF
GRUB_DEFAULT=debi
GRUB_TIMEOUT=$grub_timeout
GRUB_TIMEOUT_STYLE=menu
EOF

    if command_exists update-grub; then
        grub_cfg=/boot/grub/grub.cfg
        update-grub
    elif command_exists grub2-mkconfig; then
        tmp=$(mktemp)
        grep -vF zz_debi /etc/default/grub > "$tmp"
        cat "$tmp" > /etc/default/grub
        rm "$tmp"
        # shellcheck disable=SC2016
        echo 'zz_debi=/etc/default/grub.d/zz-debi.cfg; if [ -f "$zz_debi" ]; then . "$zz_debi"; fi' >> /etc/default/grub
        grub_cfg=/boot/grub2/grub.cfg
        grub2-mkconfig -o "$grub_cfg"
    else
        err 'Could not find "update-grub" or "grub2-mkconfig" command'
    fi

    save_grub_cfg="tee -a $grub_cfg"
fi

installer_directory="$boot_directory$installer"

# shellcheck disable=SC2034
mem=$(grep ^MemTotal: /proc/meminfo | { read -r x y z; echo "$y"; })
[ $((mem / 1024)) -lt 483 ] && kernel_params="$kernel_params lowmem/low="

$save_grub_cfg 1>&2 << EOF
menuentry 'Debian Installer' --id debi {
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    linux $installer_directory/linux$kernel_params
    initrd $installer_directory/initrd.gz
}
EOF
