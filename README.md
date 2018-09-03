# Setup Clean Debian OS for Your (Cloud) VPS

## Step 1. (Todo)

## Step 2. Run the Script

Replace following `<OPTIONS>` with your options.

```
sh -c "$(wget -O - https://github.com/brentybh/debian-netboot/raw/master/netboot.sh)" -- <OPTIONS>
```

### All Options

 - `-c <COUNTRY>` Debian Installer Country. Default is `US`.
 - `-h <HOST>` Hostname. Default is `debian`.
 - `-t <TRANSPORT>` Transport protocol for archive mirror only (not security repo). Default is `http`. `https` and `ftp` is also available.
 - `-m <MIRROR>` Host name for archive mirror only (not security repo). Default is `deb.debian.org`.
 - `-d <DIRECTORY>` Directory path relative to root of the mirror. Default is `/debian`.
 - `-r <SUITE>` Suite to install. Suite name (`stable`, `testing`, etc.) or releases code name (`stretch`, etc.) Default is `stretch`.
 - `-u <USERNAME>` Username of admin account with sudo privilege. Default is `debian`.
 - `-p <PASSWORD>` Password of the account. If not specified, it will be asked interactively.
 - `-z <TIMEZONE>` [Time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). Default is `UTC`.
 - `-t <NTPSERVER>` NTP server. Default is `pool.ntp.org`.
 - `-g <UPGRADE>` Whether to upgrade packages after debootstrap. Default is `full-upgrade`. `none` and `safe-upgrade` is also available.
 - `-s <SECURITY>` Custom URL for security repository mirror. Default is `http://security.debian.org/debian-security`.
 - `-l` Security mirror linking. If the option present, security repository will be setup as same as the archive mirror instead of `security.debian.org`.

### Chinese Special

If `-c CN` is used, Chinese Special options will be setup for good connectivity and experience against GFW.

 - Default archive mirror is `https://chinanet.mirrors.ustc.edu.cn/debian`.
 - Default security mirror is `https://chinanet.mirrors.ustc.edu.cn/debian-security`.
 - Default time zone is `Asia/Shanghai`.
 - Default NTP server is `ntp1.aliyun.com`.
 - All custom settings will override above defaults.
 - Security mirror linking (`-l`) will be turned on and can't be turned off. Specify separate security mirror by `-s` option.
