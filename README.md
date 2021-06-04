# Debian Network Reinstall Script

## 甲骨文云服务器：重装 Debian

下载脚本：

```
curl -fLO https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh && chmod a+rx debi.sh
```

运行脚本：

```
sudo ./debi.sh --cdn --network-console --ethx --bbr --user root --password <这里设置 root 密码>
```

* 以上命令选项开启了 BBR；设置了网卡名称形式是 `eth0` 而不是 `ens3` 这种。
* 如果是一般的 x86 架构 64 位机器（不是 ARM 架构的），还可以添加 `--cloud-kernel` 使用轻量版内核。
* 不加 `--password` 选项会提示输入密码。

如果没有报错可以重启：

```
sudo shutdown -r now
```

约 30 秒后可以尝试 SSH 登录 `installer` 用户，密码与之前设置的相同。如果成功连接，可以按 Ctrl-A 然后再按 4 监控安装日志。安装完成后会自动重启进入新系统。


### [甲骨文云服务器：自动获取 IPv6](https://github.com/bohanyang/debi/wiki/%E7%94%B2%E9%AA%A8%E6%96%87%E4%BA%91%E6%9C%8D%E5%8A%A1%E5%99%A8%E8%87%AA%E5%8A%A8%E8%8E%B7%E5%8F%96-IPv6)
### [甲骨文云服务器：纯 IPv6 网络（无公网 IPv4）下安装方法](https://github.com/bohanyang/debi/wiki/%E7%94%B2%E9%AA%A8%E6%96%87%E4%BA%91%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%BA%AF-IPv6-%E7%BD%91%E7%BB%9C%EF%BC%88%E6%97%A0%E5%85%AC%E7%BD%91-IPv4%EF%BC%89%E4%B8%8B%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95)

## Introduction

This script is written to reinstall a VPS/virtual machine to Debian 10 Buster.

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
    curl -fLO  --resolve 'raw.githubusercontent.com:443:2a04:4e42::133' https://raw.githubusercontent.com/bohanyang/debi/master/debi.sh

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

 * `--ip <string>` Disable the auto network config (DHCP) and configure a static IP address, e.g. `10.0.0.2`, `1.2.3.4/24`, `2001:2345:6789:abcd::ef/48`
 * `--netmask <string>` e.g. `255.255.255.0`, `ffff:ffff:ffff:ffff::`
 * `--gateway <string>` e.g. `10.0.0.1`, `none` if no gateway
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
