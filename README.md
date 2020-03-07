# dotfiles-arch

## Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Disk setup](#disk-setup)
4. [GRUB installation](#installing-grub)
5. [Display/Window managers](#display-and-window-managers)

## Overview
This repoistory contains the dotfiles for my Arch Linux installation, as well as a step-by-step guide on how to install Arch Linux from scratch. It assumes you have a working knowledge of UNIX and a functional knowledge of basic GNU and CLI utilities.

## Getting Started
### Formatting your USB
Before diving in, it is good practice to format your USB device first. After plugging in your USB, you should be identify it by running the command below. It will be less of a headache if you perform all these operations as root (via `su -` or `sudo`). Your USB device will likely be at the bottom of the STDOUT and will resemble something like the following:

```sh
  $ fdisk -l
  ...
  Disk /dev/sda: 119.54 GiB, 128345702400 bytes, 250675200 sectors
  Disk model: Flash Drive FIT 
  Units: sectors of 1 * 512 = 512 bytes
  Sector size (logical/physical): 512 bytes / 512 bytes
  I/O size (minimum/optimal): 512 bytes / 512 bytes
  Disklabel type: dos
  Disk identifier: 0x3372b9d9
```

After identifying your drive, you can format it via `fdisk /dev/sda`. Keep it mind that you will likely have to chance `sda` to whatever you determined from the output of the previous command. Delete all the patitions from the disk with the `d` option, until `p` no longer lists any devices. If you are successful, running `lsblk` will show your USB device without any subdevices/partitions.
 
 ```sh
  $ lsblk
    NAME                 MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sda                    8:0    1 119.5G  0 disk 
    nvme0n1              259:0    0   477G  0 disk 
    ├─nvme0n1p1          259:1    0   499M  0 part 
    ...
```

### Burning the latest Arch Linux ISO
You need the ISO file in order to burn it to a USB and install it on your computer. You can download the correct ISO for your region from the official download page here (https://www.archlinux.org/download/). Keep in mind that these ISOs might differ depending on mirror server, so choose it carefully and from a reputable source.

Once you've downloaded the ISO, you can easily burn it to your USB device using `dd`. Remember to point the `if` argument to the location to which you downloaded the ISO and the `of` argument to the USB device onto which to burn it. Depending on the capabilities of your drive and your USB protocol version, this might take a minute.

```sh
  $ dd bs=4M if=./archlinux-2020.03.01-x86_64.iso of=/dev/sda status=progress oflag=sync
    679477248 bytes (679 MB, 648 MiB) copied, 24 s, 28.3 MB/s
    162+1 records in
    162+1 records out
    682622976 bytes (683 MB, 651 MiB) copied, 24.145 s, 28.3 MB/s
```

## Disk setup
Once you have a bootable ISO USB, you can restart your computer and boot into it manually through your manual boot menu. The ISO should automatically login as root and you should be placed in the root user's home directory. You can verify this is the case by running `ls` and checking if there is a file called `install.txt`.

### Configuring Wi-Fi
You may run into a situation where you need to connect to the internet to successfully complete installation. To connect to Wi-Fi, run the following command. It will poll for avaliable devices and networks, and then open a UI prompting you to select a network and enter its connection credentials.

```sh
  $ wifi-menu
```

After entering credentials, you can verify that a connection has been established by pinging a known website. If successful, `ping` should report recieving 64-byte packets from your hostname:

```sh
  $ ping 1.1.1.1
  PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
  64 bytes from 1.1.1.1: icmp_seq=1 ttl=59 time=17.6 ms
  64 bytes from 1.1.1.1: icmp_seq=2 ttl=59 time=23.3 ms

  --- 1.1.1.1 ping statistics ---
  3 packets transmitted, 3 received, 0% packet loss, time 2004ms
```

### Partitioning
To install Arch Linux, there must be allocated free space on some internal SSD/HDD. This installation guide will not go into how to shrink or delete existing partitions, but I recommend at least 100GiB as anything less than that starts to yield funky and unexpected failures when dealing with programs like Anaconda (https://www.anaconda.com/distribution/) and Docker (https://docs.docker.com/install/).

### Setting up LVM

## Installing GRUB

## Display and Window Managers
