![alt tag](calico.jpg)

CALICO
------

Cli for Armbian Linux Image COnfiguration

Version
-------

0.8.5

Introduction
------------

Calico is a CLI for Armbian Linux Image Configuration.
It is a wrapper around the Armbian build system making preconfiguration of images easier.

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
