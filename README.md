# Setup Clean Debian OS for Your (Cloud) VPS

## Step 1. Preparation

 - A clean normally running true virtualization (e.g. KVM) VPS with GRUB 2 and VNC access. This script have been tested on SolusVM KVM VPS & Alibaba Cloud ECS with Debian 9 & Ubuntu 16.04.
 - Then check `/etc/default/grub` with your preferred editor (e.g. `nano` or `vi`).
 - Set `GRUB_DEFAULT` to `debi` select the installer to boot automatically after timeout.
 - Make sure there's reasonable number for `GRUB_TIMEOUT` **timeout**. You can just set `GRUB_TIMEOUT=10` which will be fine.
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

**Remember** to enter your current user's password for `sudo` (if need) and then enter the new user's password (if not specified by `--password`).

### All Options

 - `--template foobar` Selected template (see below)
 - `--hostname debian` Hostname. Precedence: provided value > reverse DNS record > the default value `debian`
 - `--protocol http` Transport protocol to use with the repository mirror (not for the security mirror). Possible values: `http`, `https`, `ftp`, etc.
 - `--mirror deb.debian.org` Hostname of the repository mirror (not for the security mirror)
 - `--directory /debian` Directory of the repository mirror
 - `--suite stretch` Selected suite to install (`stable`, `testing`, `stretch`, etc.)
 - `--username debian` Username of the administrator account with sudo privilege
 - `--password secret` Password of the account **(if not specified, it will be asked interactively)**
 - `--timezone UTC` [Time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)
 - `--ntp-server pool.ntp.org` NTP server
 - `--upgrade full-upgrade` Whether to upgrade packages after debootstrap (`none`, `safe-upgrade`, `full-upgrade`)
 - `--security-mirror http://security.debian.org/debian-security` Specify a URL for the security mirror or set to `true` to use the same mirror as the repository mirror instead of the default one
 - `--filesystem ext4` Filesystem for partition
 - `--disk-encryption` Enable full disk encryption. Since it can't be fully automated currently, you'll need physical console (VNC) access to go through the steps
 - `--ip 12.34.56.78` Configure network manually with an IP address **(the following 3 network related options only work when an IP address is provided here)**
 - `--netmask 255.255.255.0` Netmask for manual network configuration
 - `--gateway 12.34.56.1` Gateway for manual network configuration
 - `--dns "1.1.1.1 1.0.0.1"` DNS for manual network configuration
 - `--include "ca-certificates curl fail2ban openssl whois"` Include additional packages to install
 - `--manual` Manually configure user account and disk partition, etc. Network connection, the repository and security mirrors, time zone and NTP server are already auto-configured
 - `--ssh-password installerSecret` Enable SSH access to the installer with a password. You can login to `installer` user and continue installation manually or just check system logs.
 - `--ssh-keys https://example.com/.ssh/authorized_keys` Enable SSH access to the installer with a URL of the file contains authorized public keys. (see above) You can't access with password if authorized public keys are provided here.
 - `--dry-run` Generate `preseed.cfg` and save to current directory but don't actually do anything
 - `--architecture amd64` Specify an architecture (useful under CentOS)
 - `--boot-partition` Use `/` as the boot directory for the GRUB boot entry instead of `/boot`, useful under LVM machines with an independent boot partition

### Templates

You can select a template for quickly applying options. All custom settings will override template values.

#### `china`

 - `--protocol https`
 - `--mirror chinanet.mirrors.ustc.edu.cn`
 - `--security-mirror true`
 - `--timezone Asia/Shanghai`
 - `--ntp-server cn.ntp.org.cn`
 - `--dns "156.154.70.5 156.154.71.5"`

#### `cloud`

 - `--protocol https`
 - `--mirror cdn-aws.deb.debian.org`
 - `--security-mirror true`
 - `--ntp-server time.google.com`

## Step 3. Entering Debian Installer

 - Keep your SSH connection and **open VNC console** on your Provider's control panel.
 - `sudo reboot` with your SSH and the VM should **reboot**.
 - Switch to your VNC window **quickly**. You should enter the **GRUB selection menu** now.
 - If you've configured correct `GRUB_DEFAULT`, it should be booted into installer automatically after timeout.
 - Or, use your keyboard to **select** `Debian Installer` and **enter** it. Also, **be quick**, just do not miss the `GRUB_TIMEOUT` timeout you've set.
 - Finally, you should see the screen of Debian Installer now. It will setup all things automatically and reboot when complete.
