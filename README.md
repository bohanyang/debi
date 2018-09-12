# Setup Clean Debian OS for Your (Cloud) VPS

## Step 1. (Todo)

## Step 2. Run the Script

Check these dependencies:

- `ca-certificates` (if using https)
- `cpio`
- `gzip`
- `mkpasswd` (`whois` package)
- `sed`
- `wget`

Replace following `<OPTIONS>` with your options.

```
sudo sh -c "$(wget -O - https://github.com/brentybh/debian-netboot/raw/master/netboot.sh)" -- <OPTIONS>
```

### All Options

 - `-c US` Debian Installer Country
 - `-fqdn localhost` FQDN including hostname and domain
 - `-proto https` Transport protocol for archive mirror only but not security repository (`http`, `https`, `ftp`)
 - `-host dpvctowv9b08b.cloudfront.net` Host for archive mirror only but not security repository
 - `-dir /debian` Directory path relative to root of the mirror
 - `-suite stretch` Suite (`stable`, `testing`, `stretch`, etc.)
 - `-u ubuntu` Username of admin account with sudo privilege
 - `-p secret` Password of the account (if not specified, it will be asked interactively)
 - `-tz UTC` [Time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)
 - `-ntp time.google.com` NTP server
 - `-upgrade full-upgrade` Whether to upgrade packages after debootstrap (`none`, `safe-upgrade`, `full-upgrade`)
 - `-s https://dpvctowv9b08b.cloudfront.net/debian-security` Custom URL for security repository mirror
 - `-ip 1.2.3.4` Configure network manually with an IP address (following options only work when IP address specified)
 - `-cidr 255.255.255.0` Netmask for manual network configuration
 - `-gw 1.2.3.1` Gateway for manual network configuration
 - `-ns "1.1.1.1 156.154.70.5 8.8.8.8"` DNS for manual network configuration
 - `-add "ca-certificates curl openssl"` Include individual additional packages to install

### Chinese Special

If `-c CN` is used, Chinese Special options will be setup for good connectivity and experience against GFW.

 - Default archive mirror is `https://chinanet.mirrors.ustc.edu.cn/debian`.
 - Default security mirror is `https://chinanet.mirrors.ustc.edu.cn/debian-security`.
 - Default time zone is `Asia/Shanghai`.
 - Default NTP server is `ntp1.aliyun.com`.
 - All custom settings will override above defaults.

Finally, reboot and enter Debian Installer. It will setup all things automatically.
