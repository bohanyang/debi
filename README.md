# VPS Re-install Debian Script

Now ready for Debian 10 (buster)!

## Introduction

This script is used to re-install VPS to **Debian 9 (stretch) or 10 (buster)** with the official installer, but semi-automatically.

## How It Works

1. Generate a preseed file to automate installation
2. Download Debian Installer to the boot directory
3. Alter GRUB2 configuration to boot the installer

## Usage

    sudo bash -c "$(wget -qO- https://github.com/brentybh/debian-netboot/raw/master/netboot.sh)" -- <OPTIONS>

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
 - `--gpt`
 - `--efi`
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
