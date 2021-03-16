# Debian Network Reinstall Script

## Introduction

This script is written to reinstall a VPS/virtual machine to Debian 10 Buster.

## Should Work On

### Virtualization Platform

 * SolusVM/OpenStack/DigitalOcean/Vultr/Linode/Proxmox/QEMU KVM (BIOS boot)
 * Oracle Cloud Infrastructure (with `--force-efi-extra-removable`; UEFI boot)
 * Google Cloud Compute Engine (with manually configured VPC internal IP and gateway; UEFI boot)
 * AWS EC2 & Lightsail (BIOS boot)
 * Hyper-V & Azure (Generation 1 BIOS boot & Generation 2 UEFI boot)

### Original OS

 * Debian 8 or later
 * Ubuntu 14.04 or later
 * CentOS 7 or later

## How It Works

1. Generate a preseed file to automate installation
2. Download the 'Debian-Installer' to the `/boot` directory
3. Append a menu entry of the installer to the GRUB2 configuration file

## Usage

### 1. Download

Download the script with curl:

    curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh

or wget:

    wget -O debi.sh https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh

### 2. Run

Run the script under root or using sudo:

    sudo chmod a+rx debi.sh
    sudo ./debi.sh

By default, an admin user `debian` with sudo privilege will be created during the installation. Use `--user root` if you prefer.

### 3. Reboot

If everything looks good, reboot the machine:

    sudo shutdown -r now

Otherwise, you can run this command to revert all changes made by the script:

    sudo rm -rf debi.sh /etc/default/grub.d/zz-debi.cfg /boot/debian-* && { sudo update-grub || sudo grub2-mkconfig -o /boot/grub2/grub.cfg; }

## Available Options

 * `--ip <string>` Disable the auto network config (DHCP) and configure a static IP address, e.g. `10.0.0.2`, `1.2.3.4/24`, `2001:2345:6789:abcd::ef/48`
 * `--netmask <string>` e.g. `255.255.255.0`, `ffff:ffff:ffff:ffff::`
 * `--gateway <string>` e.g. `10.0.0.1`
 * `--dns '8.8.8.8 8.8.4.4'` (Default IPv6 DNS: `2001:4860:4860::8888 2001:4860:4860::8844`)
 * `--hostname <string>` FQDN hostname (includes the domain name), e.g. `server1.example.com`
 * `--network-console` Enable the network console of the installer. `ssh installer@ip` to connect
 * `--suite buster`
 * `--mirror-protocol http` or `https` or `ftp`
 * `--https` alias to `--mirror-protocol https`
 * `--mirror-host deb.debian.org`
 * `--mirror-directory /debian`
 * `--security-repository http://security.debian.org/debian-security` Magic value: `'mirror' = <mirror-protocol>://<mirror-host>/<mirror-directory>/../debian-security`
 * `--no-account-setup, --no-user` **(Manual installation)** Proceed account setup manually in VNC or remote console.
 * `--username, --user debian` New user with `sudo` privilege or `root`
 * `--password <string>` Password of the new user. **You'll be prompted if you choose to not specify it here**
 * `--authorized-keys-url <string>` URL to your authorized keys for SSH authentication. e.g. `https://github.com/torvalds.keys`
 * `--sudo-with-password` Require password when the user invokes `sudo` command
 * `--timezone UTC` https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
 * `--ntp 0.debian.pool.ntp.org`
 * `--no-disk-partitioning, --no-part` **(Manual installation)** Proceed disk partitioning manually in VNC or remote console
 * `--disk <string>` Manually select a disk for installation. **Please remember to specify this when more than one disk is available!** e.g. `/dev/sda`
 * `--no-force-gpt` By default, GPT rather than MBR partition table will be created. This option disables it.
 * `--bios` Don't create *EFI system partition*. If GPT is being used, create a *BIOS boot partition* (`bios_grub` partition). Default if `/sys/firmware/efi` is absent. [See](https://askubuntu.com/a/501360)
 * `--efi` Create an *EFI system partition*. Default if `/sys/firmware/efi` exists
 * `--filesystem ext4`
 * `--kernel <string>` Choose an package for the kernel image
 * `--cloud-kernel` Choose `linux-image-cloud-amd64` as the kernel image
 * `--no-install-recommends`
 * `--install 'ca-certificates libpam-systemd'`
 * `--safe-upgrade` **(Default)** `apt upgrade --with-new-pkgs`. [See](https://salsa.debian.org/installer-team/pkgsel/-/blob/master/debian/postinst)
 * `--full-upgrade` `apt dist-upgrade`
 * `--no-upgrade` 
 * `--ethx` Disable *Consistent Network Device Naming* to get interface names like *ethX* back
 * `--bbr` Enable TCP BBR congestion control
 * `--hold` Don't reboot or power off after installation
 * `--power-off` Power off after installation rather than reboot
 * `--architecture <string>` e.g. `amd64`, `i386`, `arm64`, `armhf`, etc.
 * `--boot-directory <string>`
 * `--firmware` Load additional [non-free firmwares](https://wiki.debian.org/Firmware#Firmware_during_the_installation)
 * `--force-efi-extra-removable` [See](https://wiki.debian.org/UEFI#Force_grub-efi_installation_to_the_removable_media_path). **Useful on Oracle Cloud**
 * `--grub-timeout 5` How many seconds the GRUB menu shows before entering the installer
 * `--dry-run` Print generated preseed and GRUB entry without downloading the installer and actually saving them

### Presets

### `--cdn`

 * `--mirror-protocol https`
 * `--mirror-host deb.debian.org`
 * `--security-repository mirror`

### `--aws`

 * `--mirror-protocol https`
 * `--mirror-host cdn-aws.deb.debian.org`
 * `--security-repository mirror`

### `--china`

 * `--dns '223.5.5.5 223.6.6.6'`
 * `--mirror-protocol https`
 * `--mirror-host mirrors.aliyun.com`
 * `--security-repository mirror`
 * `--ntp ntp.aliyun.com`
