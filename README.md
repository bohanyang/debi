# Debian Network Reinstall Script

## Introduction

This script is used to reinstall the Linux OS of a KVM-based VPS or a Hyper-V virtual machine to Debian 10 Buster.

## How It Works

1. Generate a preseed file to automate installation
2. Download the 'Debian-Installer' to the `/boot` directory
3. Append a menu entry of the installer to the GRUB2 configuration file

## Usage

    sudo bash -c "$(curl -fsSL https://github.com/bohanyang/debian-network-reinstall/raw/master/netinst.sh)" -- <OPTIONS>

## Available Options

 - `--preset` (`china`/`cloud`)
 - `--ip`
 - `--netmask`
 - `--gateway`
 - `--dns '8.8.8.8 8.8.4.4'`
 - `--hostname debian`
 - `--installer-password`
 - `--authorized-keys-url`
 - `--suite buster`
 - `--mirror-protocol http` (`http`/`https`/`ftp`)
 - `--mirror-host deb.debian.org`
 - `--mirror-directory /debian`
 - `--security-repository http://security.debian.org/debian-security`
 - `--skip-account-setup`
 - `--username debian`
 - `--password`
 - `--timezone UTC` https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
 - `--ntp 0.debian.pool.ntp.org`
 - `--skip-partitioning`
 - `--partitioning-method regular`
 - `--disk`
 - `--force-gpt` Create a *GUID Partition Table* **(Default)**
 - `--no-force-gpt`
 - `--bios` Don't create *EFI system partition*. If GPT is being used, create a *BIOS boot partition* (`bios_grub` partition). Default if `/sys/firmware/efi` is absent. [See](https://askubuntu.com/a/501360)
 - `--efi` Create an *EFI system partition*. Default if `/sys/firmware/efi` exists
 - `--filesystem ext4`
 - `--kernel` Choose an package for the kernel image
 - `--cloud-kernel` Choose `linux-image-cloud-amd64` as the kernel image
 - `--no-install-recommends`
 - `--install`
 - `--safe-upgrade`
 - `--full-upgrade`
 - `--eth` Disable *Consistent Network Device Naming* to get `eth0`, `eth1`, etc. back
 - `--bbr`
 - `--power-off`
 - `--architecture`
 - `--boot-partition`
 - `--dry-run`

## Presets

### `china`

 - `--dns '223.5.5.5 223.6.6.6'`
 - `--protocol https`
 - `--mirror mirrors.aliyun.com`
 - `--security true`
 - `--ntp ntp.aliyun.com`

### `cloud`

 - `--dns '1.1.1.1 1.0.0.1'`
 - `--protocol https`
 - `--mirror deb.debian.org`
 - `--security true`
 - `--ntp 0.debian.pool.ntp.org`
