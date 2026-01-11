![alt tag](calico.jpg)

CALICO
------

Cli for Armbian Linux Image COnfiguration

Version
-------

0.9.1

Introduction
------------

Calico is a CLI for Armbian Linux Image Configuration.
It is a wrapper around the Armbian build system making preconfiguration of images easier.

Where possible the script will use sensible defaults to configure the image.
If there are not enough defaults, or the manual option is used for compile,
the armbian build system menu interface will be launched.

License
-------

CC BY-SA: https://creativecommons.org/licenses/by-sa/4.0/

Fund me here: https://ko-fi.com/richardatlateralblast

Goals
-----

The goals of this script are to:

Provide a command line processor that:

- Can configure network and other settings in the Armbian image.

Requirements
------------

- Armbian build system
- Docker
- qemu-system-arm
- qemu-system-riscv
- binfmt-support
- qemu-user-binfmt

Usage
-----

Help:

```bash
./calico.sh --help
```

Options:

```bash
./calico.sh --usage options
```
Version:

```bash
./calico.sh --version
```

Examples
--------

List boards:

```bash
./calico.sh --list boards
```

List images:

```bash
./calico.sh --list images
```

Manual compile:

```bash
./calico.sh --complile --manual
```

Configure compile for orangepipc board with IP, gateway, DNS, etc:

```bash
./calico.sh --compile --board orangepipc --ip 192.168.1.100 --gateway 192.168.1.1 --dns 8.8.8.8 --netmask 255.255.255.0
```

Mount image:

```bash
./calico.sh --mount --image /path/to/image.img
```

Unmount image:

```bash
./calico.sh --unmount --image /path/to/image.img
```
