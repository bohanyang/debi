# Debian Network Reinstall Script

[中文说明 ↓](#中文说明)

## Introduction

This script is written to reinstall VPS/VMs to minimal Debian.

## Platforms

- ✔ KVM or physical machines ❌ Containers
- ✔ Debian or Ubuntu or Red Hat Linux as original OS with GRUB 2 bootloader
- ✔ MBR or GPT partition table
- ✔ Multiple disks or LVM
- ✔ IPv4 or IPv6
- ✔ Legacy BIOS or UEFI boot
- ✔ Most VPS or cloud providers
- ⚠️ Google Compute Engine - **MUST** manually specify IP/CIDR and gateway of VPC
- ⚠️ AWS EC2 or Lightsail - Does **NOT** work with UEFI boot

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

    chmod a+rx debi.sh
    sudo ./debi.sh

By default, an admin user `debian` with sudo privilege will be created during the installation. Use `--user root` if you prefer.

### 3. Reboot

If everything looks good, reboot the machine:

    sudo shutdown -r now

Otherwise, you can run this command to revert all changes made by the script:

    sudo rm -rf debi.sh /etc/default/grub.d/zz-debi.cfg /boot/debian-* && { sudo update-grub || sudo grub2-mkconfig -o /boot/grub2/grub.cfg; }

## Available Options

### Presets

| Region | Alias          | Mirror                               | DNS        | NTP                 |
|--------|----------------|--------------------------------------|------------|---------------------|
| Global | Default        | https://deb.debian.org               | Google     | time.google.com     |
| Global | `--cloudflare` | https://deb.debian.org               | Cloudflare | time.cloudflare.com |
| Global | `--aws`        | https://cdn-aws.deb.debian.org       | Google     | time.aws.com        |
| China  | `--ustc`       | https://mirrors.ustc.edu.cn          | DNSPod     | time.amazonaws.cn   |
| China  | `--tuna`       | https://mirrors.tuna.tsinghua.edu.cn | DNSPod     | time.amazonaws.cn   |
| China  | `--aliyun`     | https://mirrors.aliyun.com           | AliDNS     | time.amazonaws.cn   |

 * `--interface <string>` Manually select a network interface, e.g. eth1
 * `--ethx` Disable *Consistent Network Device Naming* to get interface names like *ethX* back
 * `--ip <string>` Disable the auto network config (DHCP) and configure a static IP address, e.g. `10.0.0.2`, `1.2.3.4/24`, `2001:2345:6789:abcd::ef/48`
 * `--static-ipv4` Disable the auto network config (DHCP) and configure with the current IPv4 address and gateway detected automatically
 * `--netmask <string>` e.g. `255.255.255.0`, `ffff:ffff:ffff:ffff::`
 * `--gateway <string>` e.g. `10.0.0.1`, `none` if no gateway
 * `--dns '8.8.8.8 8.8.4.4'`
 * `--dns6 '2001:4860:4860::8888 2001:4860:4860::8844'` (effective only if IPv6 is specified)
 * `--hostname <string>` FQDN hostname (includes the domain name), e.g. `server1.example.com`
 * `--network-console` Enable the network console of the installer. `ssh installer@ip` to connect
 * `--version 12` Supports: `10`, `11`, `12`, `13`
 * `--suite bullseye` **Please use `--version` instead if you don't have special needs.** e.g. `stable`, `testing`, `sid`
 * `--release-d-i` d-i (Debian Installer) for the released versions: 12 (bookworm), 11 (bullseye) and 10 (buster)
 * `--daily-d-i` Use latest daily build of d-i (Debian Installer) for the unreleased version: 13 (trixie), sid (unstable)
 * `--mirror-protocol http` or `https` or `ftp`
 * `--https` alias to `--mirror-protocol https`
 * `--reuse-proxy` Reuse the value of `http(s)_proxy` environment variable as the mirror proxy
 * `--proxy, --mirror-proxy` Set an HTTP proxy for APT and downloads
 * `--mirror-host deb.debian.org`
 * `--mirror-directory /debian`
 * `--security-repository http://security.debian.org/debian-security` Magic value: `'mirror' = <mirror-protocol>://<mirror-host>/<mirror-directory>/../debian-security`
 * `--no-account-setup, --no-user` **(Manual installation)** Proceed account setup manually in VNC or remote console.
 * `--username, --user debian` New user with `sudo` privilege or `root`
 * `--password <string>` Password of the new user. **You'll be prompted if you choose to not specify it here**
 * `--authorized-keys-url <string>` URL to your authorized keys for SSH authentication. e.g. `https://github.com/torvalds.keys`
 * `--sudo-with-password` Require password when the user invokes `sudo` command
 * `--timezone UTC` e.g. `Asia/Shanghai` for China (UTC+8) https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
 * `--ntp time.google.com`
 * `--no-disk-partitioning, --no-part` **(Manual installation)** Proceed disk partitioning manually in VNC or remote console
 * `--disk <string>` Manually select a disk for installation. **Please remember to specify this when more than one disk is available!** e.g. `/dev/sda`
 * `--no-force-gpt` By default, GPT rather than MBR partition table will be created. This option disables it.
 * `--bios` Don't create *EFI system partition*. If GPT is being used, create a *BIOS boot partition* (`bios_grub` partition). Default if `/sys/firmware/efi` is absent. [See](https://askubuntu.com/a/501360)
 * `--efi` Create an *EFI system partition*. Default if `/sys/firmware/efi` exists
 * `--esp 106` Size of the *EFI system partition*. e.g. `106`, `538` and `1075` result to 100 MiB, 512 MiB, 1 GiB respectively
 * `--filesystem ext4`
 * `--kernel <string>` Choose an package for the kernel image
 * `--cloud-kernel` Choose `linux-image-cloud-amd64` or `...arm64` as the kernel image
 * `--bpo-kernel` Choose the kernel image from Debian Backports (newer version from the next Debian release)
 * `--no-install-recommends`
 * `--apt-non-free-firmware`, `--apt-non-free`, `--apt-contrib`, `--apt-src`, `--apt-backports`
 * `--no-apt-non-free-firmware`, `--no-apt-non-free`, `--no-apt-contrib`, `--no-apt-src`, `--no-apt-backports`
 * `--install 'ca-certificates libpam-systemd'` Install additional APT packages. Space-separated and quoted.
 * `--safe-upgrade` **(Default)** `apt upgrade --with-new-pkgs`. [See](https://salsa.debian.org/installer-team/pkgsel/-/blob/master/debian/postinst)
 * `--full-upgrade` `apt dist-upgrade`
 * `--no-upgrade`
 * `--bbr` Enable TCP BBR congestion control
 * `--ssh-port <integer>` SSH port
 * `--hold` Don't reboot or power off after installation
 * `--power-off` Power off after installation rather than reboot
 * `--architecture <string>` e.g. `amd64`, `i386`, `arm64`, `armhf`, etc.
 * `--firmware` Load additional [non-free firmwares](https://wiki.debian.org/Firmware#Firmware_during_the_installation)
 * `--no-force-efi-extra-removable` [See](https://wiki.debian.org/UEFI#Force_grub-efi_installation_to_the_removable_media_path)
 * `--grub-timeout 5` How many seconds the GRUB menu shows before entering the installer
 * `--force-lowmem <integer>` Valid values: 0, 1, 2. Force [low memory level](https://salsa.debian.org/installer-team/lowmem). Useful if your machine has memory less than 500M where level 2 is set (see issue #45). `--force-lowmem 1` may solve it. 
 * `--dry-run` Print generated preseed and GRUB entry without downloading the installer and actually saving them
 * `--cidata ./cidata-example` Custom data for cloud-init. **VM provider's data source will be IGNORED.** See example.

## 中文说明

下载脚本：

```
curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh && chmod a+rx debi.sh
```

运行脚本：

```
sudo ./debi.sh --cdn --network-console --ethx --bbr --user root --password <新系统用户密码>
```

* `--bbr` 开启 BBR
* `--ethx` 网卡名称使用传统形式，如 `eth0` 而不是 `ens3`
* `--cloud-kernel` 安装占用空间较小的 `cloud` 内核，但可能会导致 UEFI 启动的机器（如 Oracle、Azure 及 Hyper-V、Google Cloud 等）VNC 黑屏。BIOS 启动的普通 VPS 则没有此问题。
* 默认时区为 UTC，添加 `--timezone Asia/Shanghai` 可使用中国时区。
* 默认使用 Debian 官方 CDN 镜像源（deb.debian.org），添加 `--ustc` 可使用中科大镜像源。

如果没有报错可以重启：

```
sudo shutdown -r now
```

约 30 秒后可以尝试 SSH 登录 `installer` 用户，密码与之前设置的相同。如果成功连接，可以按 Ctrl-A 然后再按 4 监控安装日志。安装完成后会自动重启进入新系统。
