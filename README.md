# Debian Network Reinstall Script

[General description in English ↓](#introduction)

## VPS 网络重装 Debian 11 脚本

**暂不支持 Oracle Linux 作为原系统。创建新机器时请选择 Ubuntu 20.04 或 18.04 系统模板。**

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
* 默认使用 Debian 官方 CDN 镜像源（deb.debian.org），添加 `--china` 可使用阿里云镜像源。

如果没有报错可以重启：

```
sudo shutdown -r now
```

约 30 秒后可以尝试 SSH 登录 `installer` 用户，密码与之前设置的相同。如果成功连接，可以按 Ctrl-A 然后再按 4 监控安装日志。安装完成后会自动重启进入新系统。


### [Oracle 自动获取 IPv6](https://github.com/bohanyang/debi/wiki/%E7%94%B2%E9%AA%A8%E6%96%87%E4%BA%91%E6%9C%8D%E5%8A%A1%E5%99%A8%E8%87%AA%E5%8A%A8%E8%8E%B7%E5%8F%96-IPv6)
### [Oracle 纯 IPv6 网络（无公网 IPv4）下安装方法](https://github.com/bohanyang/debi/wiki/%E7%94%B2%E9%AA%A8%E6%96%87%E4%BA%91%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%BA%AF-IPv6-%E7%BD%91%E7%BB%9C%EF%BC%88%E6%97%A0%E5%85%AC%E7%BD%91-IPv4%EF%BC%89%E4%B8%8B%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95)

## Introduction

This script is written to reinstall a VPS/virtual machine to minimal Debian 11.

## Should Work On

### Virtualization Platform

 * SolusVM/OpenStack/DigitalOcean/Vultr/Linode/Proxmox/QEMU KVM (BIOS boot)
 * Oracle Cloud Infrastructure (UEFI boot)
 * Google Cloud Compute Engine (**Must manually configure the VPC internal IP and the gateway.** UEFI boot with Secure Boot support)
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
    
    # for IPv6-only machines
    curl -fLO --resolve 'raw.githubusercontent.com:443:2a04:4e42::133' https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh

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

 * `--interface <string>` Manually select a network interface, e.g. eth1
 * `--ethx` Disable *Consistent Network Device Naming* to get interface names like *ethX* back
 * `--ip <string>` Disable the auto network config (DHCP) and configure a static IP address, e.g. `10.0.0.2`, `1.2.3.4/24`, `2001:2345:6789:abcd::ef/48`
 * `--netmask <string>` e.g. `255.255.255.0`, `ffff:ffff:ffff:ffff::`
 * `--gateway <string>` e.g. `10.0.0.1`, `none` if no gateway
 * `--dns '8.8.8.8 8.8.4.4'` (Default IPv6 DNS: `2001:4860:4860::8888 2001:4860:4860::8844`)
 * `--hostname <string>` FQDN hostname (includes the domain name), e.g. `server1.example.com`
 * `--network-console` Enable the network console of the installer. `ssh installer@ip` to connect
 * `--version 11` Supports: `9`, `10`, `11`, `12`
 * `--suite bullseye` **For normal cases, please use `--version` instead.** e.g. `stable`, `testing`, `sid`
 * `--release-d-i` d-i (Debian Installer) for the released versions: 11 (bullseye), 10 (buster) and 9 (stretch)
 * `--daily-d-i` Use latest daily build of d-i (Debian Installer) for the unreleased version: 12 (bookworm), sid (unstable)
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
 * `--ntp 0.debian.pool.ntp.org`
 * `--no-disk-partitioning, --no-part` **(Manual installation)** Proceed disk partitioning manually in VNC or remote console
 * `--disk <string>` Manually select a disk for installation. **Please remember to specify this when more than one disk is available!** e.g. `/dev/sda`
 * `--no-force-gpt` By default, GPT rather than MBR partition table will be created. This option disables it.
 * `--bios` Don't create *EFI system partition*. If GPT is being used, create a *BIOS boot partition* (`bios_grub` partition). Default if `/sys/firmware/efi` is absent. [See](https://askubuntu.com/a/501360)
 * `--efi` Create an *EFI system partition*. Default if `/sys/firmware/efi` exists
 * `--filesystem ext4`
 * `--kernel <string>` Choose an package for the kernel image
 * `--cloud-kernel` Choose `linux-image-cloud-amd64` or `...arm64` as the kernel image
 * `--bpo-kernel` Choose the kernel image from Debian Backports (newer version from the next Debian release)
 * `--no-install-recommends`
 * `--install 'ca-certificates libpam-systemd'` Install additional APT packages. Space-separated and quoted.
 * `--safe-upgrade` **(Default)** `apt upgrade --with-new-pkgs`. [See](https://salsa.debian.org/installer-team/pkgsel/-/blob/master/debian/postinst)
 * `--full-upgrade` `apt dist-upgrade`
 * `--no-upgrade`
 * `--bbr` Enable TCP BBR congestion control
 * `--ssh-port <integer>` SSH port
 * `--hold` Don't reboot or power off after installation
 * `--power-off` Power off after installation rather than reboot
 * `--architecture <string>` e.g. `amd64`, `i386`, `arm64`, `armhf`, etc.
 * `--boot-directory <string>` Automatically set to `/` if there is an individual boot partition otherwise set to `/boot`. You can try to treak this if needed (for example setting subvolume for btrfs)
 * `--firmware` Load additional [non-free firmwares](https://wiki.debian.org/Firmware#Firmware_during_the_installation)
 * `--no-force-efi-extra-removable` [See](https://wiki.debian.org/UEFI#Force_grub-efi_installation_to_the_removable_media_path)
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
