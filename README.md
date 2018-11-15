Virtualhost Manage Script
=========================

Bash Script to easy create or delete apache virtual hosts on Debian.

By default, this script will use `$HOME/www/` as default starting point, instead of `/var/www/` in [the original script](https://github.com/RoverWire/virtualhost).

## Installation

```bash
$ cd /usr/local/bin
$ sudo wget -O virtualhost https://github.com/lelinhtinh/virtualhost/raw/master/virtualhost.sh
$ sudo chmod +x virtualhost
```

## Usage

```bash
$ sudo virtualhost [create | delete] [domain]
```

### Examples

Create a new virtual host:

```bash
$ sudo virtualhost create mysite.test
```

Delete a virtual host:

```bash
$ sudo virtualhost delete mysite.test
```
