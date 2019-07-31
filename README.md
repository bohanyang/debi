# VPS Re-install Debian Script

Now ready for Debian 10 (buster)!

## Introduction

This script is used to re-install VPS to **Debian 9 (stretch) or 10 (buster)** with the official installer, but semi-automatically.

## How It Works

1. Generate a preseed file to automate installation
2. Download Debian Installer to the boot directory
3. Alter GRUB2 configuration to boot the installer

## Usage

    sudo sh -c "$(wget -qO- https://github.com/brentybh/debian-netboot/raw/master/netboot.sh)" -- <OPTIONS>

## Available Options

 - `--preset` [`china`, `cloud`]
 - `--ip`
 - `--netmask`
 - `--gateway`
 - `--ns "8.8.8.8 8.8.4.4"`
 - `--hostname debian`
 - `--ssh-password`
 - `--ssh-keys`
 - `--protocol http` [`http`, `https`, `ftp`]
 - `--mirror deb.debian.org`
 - `--directory /debian`
 - `--suite stable`
 - `--skip-user`
 - `--username debian`
 - `--password`
 - `--timezone UTC` https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
 - `--ntp 0.debian.pool.ntp.org`
 - `--skip-part`
 - `--disk`
 - `--part`
 - `--fs ext4`
 - `--security http://security.debian.org/debian-security`
 - `--install`
 - `--upgrade full-upgrade` [`none`, `safe-upgrade`, `full-upgrade`]
 - `--poweroff`
 - `--arch`
 - `--boot-partition`
 - `--dry-run`

## Presets

### `china`

 - `--ns "156.154.70.5 156.154.71.5"`
 - `--protocol https`
 - `--mirror mirrors.aliyun.com`
 - `--security true`
 - `--timezone Asia/Shanghai`
 - `--ntp cn.ntp.org.cn`

### `cloud`

 - `--protocol https`
 - `--mirror cdn-aws.deb.debian.org`
 - `--security true`
