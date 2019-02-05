# Setup Clean Debian OS for Your (Cloud) VPS

## Step 1. Preparation

 - A clean normally running true virtualization (e.g. KVM) VPS with GRUB2 and VNC access. This script have been tested on SolusVM KVM VPS & Alibaba Cloud ECS with Debian 8/9 & Ubuntu 16.04/18.04.
 - Then check `/etc/default/grub` with your preferred editor (e.g. `nano` or `vi`).
 - Set `GRUB_DEFAULT` to `2` (which means select 3rd entry by default) will let **most of** the virtual instances boot to installer automatically after timeout.
 - Make sure there's reasonable number for `GRUB_TIMEOUT` **timeout**. You can just set `GRUB_TIMEOUT=30` which will be fine.
 - Make sure there's **no** `GRUB_HIDDEN_TIMEOUT_QUIET` and `GRUB_HIDDEN_TIMEOUT`. **Just delete them.**

Install dependencies:

```
sudo apt update && sudo apt -y install ca-certificates whois
```

## Step 2. Run the Script

Replace following `<OPTIONS>` with your options.

```
sudo sh -c "$(wget -qO- https://github.com/brentybh/debian-netboot/raw/master/netboot.sh)" -- <OPTIONS>
```

**Remember** to enter your current user's password for `sudo` (if need) and then enter the new user's password (if not specified by `-p`).

### All Options

 - `-c US` Debian Installer Country
 - `-fqdn debian` FQDN including hostname and domain. Priority: `-fqdn` option > rDNS > `debian` as default.
 - `-proto http` Transport protocol for archive mirror only but not security repository (`http`, `https`, `ftp`)
 - `-host deb.debian.org` Host for archive mirror only but not security repository
 - `-dir /debian` Directory path relative to root of the mirror
 - `-suite stretch` Suite (`stable`, `testing`, `stretch`, etc.)
 - `-u debian` Username of admin account with sudo privilege
 - `-p secret` Password of the account **(if not specified, it will be asked interactively)**
 - `-tz UTC` [Time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)
 - `-ntp pool.ntp.org` NTP server
 - `-upgrade full-upgrade` Whether to upgrade packages after debootstrap (`none`, `safe-upgrade`, `full-upgrade`)
 - `-s http://security.debian.org/debian-security` Custom URL for security repository mirror
 - `-fs ext4` Filesystem for partition
 - `-crypto` Full disk encryption (Can't be fully automated at current time. Need VNC connection to go through the steps)
 - `-ip 192.168.1.42` Configure network manually with an IP address **(the following** `-cidr`**,** `-gw` **and** `-dns` **options only work when an IP address is specified)**
 - `-cidr 255.255.255.0` Netmask for manual network configuration
 - `-gw 192.168.1.1` Gateway for manual network configuration
 - `-ns "8.8.8.8 8.8.4.4"` DNS for manual network configuration
 - `-add "ca-certificates curl fail2ban openssl whois"` Include individual additional packages to install
 - `-ssh secret` Enable network console and specify **password for SSH access during install process**. You can login with `installer` user and check system logs.
 - `-dry-run` Generate `preseed.cfg` and save to current dir but don't actually do anything

### Chinese Special

If `-c CN` is used, Chinese Special options will be setup for good connectivity and experience against GFW.

 - Default archive mirror is `https://chinanet.mirrors.ustc.edu.cn/debian`.
 - Default security mirror is `https://chinanet.mirrors.ustc.edu.cn/debian-security`.
 - Default time zone is `Asia/Shanghai`.
 - Default NTP server is `cn.ntp.org.cn`.
 - Default DNS is `156.154.70.5 156.154.71.5`.
 - All custom settings will override above defaults.

## Step 3. Entering Debian Installer

 - Keep your SSH connection and **open VNC console** on your Provider's control panel.
 - `sudo reboot` with your SSH and the VM should **reboot**.
 - Switch to your VNC window **quickly**. You should enter the **GRUB selection menu** now.
 - If you've configured correct `GRUB_DEFAULT`, it should be booted into installer automatically after timeout.
 - Or, use your keyboard to **select** `New Install` and **enter** it. Also, **be quick**, just do not miss the `GRUB_TIMEOUT` timeout you've set.
 - Finally, you should see the screen of Debian Installer now. It will setup all things automatically and reboot when complete.
