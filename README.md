# Debian Network Reinstall Script

## Introduction

This script is written to reinstall a VPS/virtual machine to Debian 10 Buster.

## Should Work On

### Virtualization Platform

 * SolusVM/OpenStack/DigitalOcean/Vultr/Linode/Proxmox/QEMU KVM (BIOS boot)
 * Oracle Cloud Infrastructure (with `--force-efi-extra-removable`; UEFI boot)
 * Google Cloud Compute Engine (manually set the VPC internal `--ip`, `--netmask`, `--gateway`; UEFI boot)
 * AWS EC2 & Lightsail (BIOS boot)
 * Hyper-V **but not Azure!** (Generation 1 BIOS boot & Generation 2 UEFI boot)

### Original OS

 * Debian 8/9/10
 * Ubuntu 14.04/16.04/18.04/20.04
 * CentOS 7/8

## How It Works

1. Generate a preseed file to automate installation
2. Download the 'Debian-Installer' to the `/boot` directory
3. Append a menu entry of the installer to the GRUB2 configuration file

## Usage

    curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh && sudo bash debi.sh <OPTIONS>

## Available Options

 * `--preset <string>` Shortcut for applying [preset options](#presets)
 * `--ip <string>` Static public/private IP, e.g. `10.0.0.2`
 * `--netmask <string>` e.g. `255.255.255.0` /  `ffff:ffff:ffff:ffff::`
 * `--gateway <string>` e.g. `10.0.0.1`
 * `--dns '8.8.8.8 8.8.4.4'` Ignored if `--ip` is not specified. Quoted string where IP addresses are seperated by spaces
 * `--hostname debian`
 * `--installer-password <string>` Enable installer network console to monitor installation status. e.g. `ssh installer@10.0.0.2`
 * `--authorized-keys-url <string>` Setup SSH public key authentication for the new user and enable installer network console. e.g. `https://github.com/bohanyang.keys`
 * `--suite buster`
 * `--mirror-protocol http` or `https` or `ftp`
 * `--mirror-host deb.debian.org`
 * `--mirror-directory /debian`
 * `--security-repository http://security.debian.org/debian-security` Magic value: `'mirror' = <mirror-protocol>://<mirror-host>/<mirror-directory>/../debian-security`
 * `--skip-account-setup`
 * `--username debian` New user with `sudo` privilege or `root`
 * `--password <string>` New user password to set. **Will be prompted if not specified here**
 * `--sudo-password` Verify the user's password when running "sudo" commands
 * `--timezone UTC` https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
 * `--ntp 0.debian.pool.ntp.org`
 * `--skip-partitioning`
 * `--disk <string>` Manually select a disk for installation. **Please remember to specify this when more than one disk is available!** e.g. `/dev/sda`
 * `--no-force-gpt` By default, GPT rather than MBR partition table will be created. This option disables it.
 * `--bios` Don't create *EFI system partition*. If GPT is being used, create a *BIOS boot partition* (`bios_grub` partition). Default if `/sys/firmware/efi` is absent. [See](https://askubuntu.com/a/501360)
 * `--efi` Create an *EFI system partition*. Default if `/sys/firmware/efi` exists
 * `--filesystem ext4`
 * `--kernel <string>` Choose an package for the kernel image
 * `--cloud-kernel` Choose `linux-image-cloud-amd64` as the kernel image
 * `--no-install-recommends`
 * `--install 'ca-certificates libpam-systemd'` Additional packages to install. Quoted string where package names are seperated by spaces. **Package names specified here will override the default list, rather than append to it**
 * `--safe-upgrade` **(Default)** `apt upgrade --with-new-pkgs`. [See](https://salsa.debian.org/installer-team/pkgsel/-/blob/master/debian/postinst)
 * `--full-upgrade` `apt dist-upgrade`
 * `--no-upgrade` 
 * `--eth` Disable *Consistent Network Device Naming* to get `eth0`, `eth1`, etc. back
 * `--bbr` Enable TCP BBR congestion control
 * `--hold` Don't reboot or power off after installation
 * `--power-off` Power off after installation rather than reboot
 * `--architecture <string>` e.g. `amd64`, `i386`, `arm64`, `armhf`, etc.
 * `--boot-partition` Should be used if `/boot` directory is mounted from a dedicated partition like a LVM setup
 * `--firmware` Load additional [non-free firmwares](https://wiki.debian.org/Firmware#Firmware_during_the_installation)
 * `--force-efi-extra-removable` [See](https://wiki.debian.org/UEFI#Force_grub-efi_installation_to_the_removable_media_path). **Useful on Oracle Cloud**
 * `--grub-timeout 5` How many seconds the GRUB menu shows **before entering the installer**
 * `--dry-run` Print generated preseed and GRUB entry without downloading the installer and actually saving them

## Presets

### `china`

 * `--dns '223.5.5.5 223.6.6.6'`
 * `--mirror-protocol https`
 * `--mirror-host mirrors.aliyun.com`
 * `--security-repository mirror`
 * `--ntp ntp.aliyun.com`

### `cloud`

 * `--dns '1.1.1.1 1.0.0.1'`
 * `--mirror-protocol https`
 * `--mirror-host deb.debian.org`
 * `--security-repository mirror`
 * `--ntp 0.debian.pool.ntp.org`
