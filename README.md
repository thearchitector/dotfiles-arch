# dotfiles-arch

## Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Disk setup](#disk-setup)
4. [GRUB installation](#installing-grub)
5. [Display/Window managers](#display-and-window-managers)

## Overview
This repoistory contains the dotfiles for my Arch Linux installation, as well as a step-by-step guide on how to install Arch Linux from scratch. It assumes you have a working knowledge of UNIX and a functional knowledge of basic GNU and CLI utilities. **There are many different ways you can choose to setup your own machine, and I am not claiming that my way is the best way for you. Several factors have gone into the procedure outlined below, so if it does not fit your beliefs or needs simply don't follow it.**

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
  2 packets transmitted, 2 received, 0% packet loss, time 2004ms
```

### Partitioning
To install Arch Linux, there must be allocated free space on some internal SSD/HDD. This installation guide will not go into how to shrink or delete existing partitions, but I recommend at least 100GiB as anything less than that starts to yield funky and unexpected failures when dealing with programs like Anaconda (https://www.anaconda.com/distribution/) and Docker (https://docs.docker.com/install/).

#### Allocating the filesystem
In order to use the avaliable space on your internal storage device, you must allocate that space to a partition. _Please note that you should already know the physical device onto which you are going to install Arch. In this tutorial that device is `/dev/nvme0n1`, but it will almost certainly be different on your machine._

To initialize the partitioning, we can again use the `fdisk` command:

```sh
  $ fdisk /dev/nvme0n1
```

A new subshell will open prompting you to enter `fdisk`-specific commands. You can check the list of commands and their descriptions by entering `m`. As we want to create a new partition, we can simply follow the default process and leave all the default values unchanged:

```sh
  Command (m for help): n
  Partition number (5-128, default 5): 5
  First sector (532828020-1000215182, default 532828020): 532828020
  Last sector, +/-sectors or +/-size{K,M,G,T,P} (532828020-1000215182, default 1000215182): 1000215182
  
  Created new partition 5 of type 'Linux filesystem' and of size 222.9 GiB.
```

<img align="right" width=450 src="https://upload.wikimedia.org/wikipedia/commons/e/e6/Lvm.svg">

Note that `fdisk` mentions that it new partition will be created with the type 'Linux filesystem'. In most cases that is totally fine, as it would allow you to allocate the space using any UNIX filesystem like ext3 or ext4. However we intend on separating our Linux filesystem from the physical storage device with a layer known as LVM (Logical Volume Manager), the hope being that it will make our lives significantly easier if something goes wrong in the future. I highly recommend you read more about the design principles and reasoning behind LVM here (https://wiki.archlinux.org/index.php/LVM#Background), but you can get a general concept of how things are arranged by the diagram on the right. 

Continuing, we need to specify that the new partition we're making does not use a standard Linux filesystem directly. Rather, it uses a special bridge partition type called 'Linux LVM'. In the diagram above, this is the 'Physical Partition'. `fdisk` allows you to modify the type of partition it will make using the `t` subcommand:

```sh
  Command (m for help): t
  Partition number (1-5, default 5): 5
  Partition type (type L to list all types): 30
  
  Changed type of partition 'Linux filesystem' to 'Linux LVM'.
```

The last step in partitioning is to tell `fdisk` to actually make the changes. You can do that with the `w` (write table to disk) subcommand:

```sh
  Command (m for help): w
  The partition table has been altered.
  Calling ioctl() to re-read partition table.
  Syncing disks.
```

### Setting up LVM
Now that the physical partition set, we can go ahead and continue to setup our different LVM abstraction layers. In this tutorial, the physical partition that was made is named `/dev/nvme0n1p5`, but will be different on your machine. **Make sure to change update your commands to respect that fact.**

#### Physical Volume
Looking at the diagram above, the second layer of abstraction that we must make is called a 'Physical Volume'. We can check that none exist by running `pvscan`, and then make one using `pvcreate`:

```sh
  $ pvscan
      No matching physical volumes found
  $ pvcreate /dev/nvme0n1p5
      Physical volume "/dev/nvme0n1p5" was successfully created.
  $ pvscan
      PV /dev/nvme0n1p5                       lvm2 [<222.87 GiB]
      ...
```

#### Volume Group
Next is the 'Volume Group'. Its job is to manage the allocated space across many different physical volumes and physical partitions. In essence, this is where the magic happens. A single volume group can control many different sectors of physical devices, effectively making a larger and dynamic drive. In this way, LVM is very similar to RAID. You can make a 'Volume Group' using the `vgcreate` command:

```sh
  $ vgcreate vpool /dev/nvme0n1p5
      Volume group "vpool" successfully created
```

#### Logical Volumes
If you are familiar with normal disk partitioning, this step will make a lot of sense as it is conceptually identical to creationg specialized partitions on a physical drive. On a familiar Linux system, these likely include the root partition `/`, the home parition `/home`, and the swap partition.

The amount of space you allocate for each of these volumes is up to you and is likely dictated by your needs and hardware. My personal approach is to always set the root (`/`) partition to 64 GiB, swap to some size related to my systems RAM, and home (`/home`) to the rest. There is a substantial amount of confusion and disagreement about what to make the size of your `swap` partition. In general I tend to follow the chart created by the folks over at Ubuntu (https://help.ubuntu.com/community/SwapFaq#How_much_swap_do_I_need.3F), and I suggest you do the same.

You can create all these logical volumes in a few short and templated commans, where the `-L` option indicates size, `-n` indicates the name of the volume, and the last argument indicates the volume group in which to create it. After creating the volumes, I suggest you make sure everything looks correct using the `lvdisplay` command.

```sh
  $ lvcreate -L 64G -n root vpool
    Logical volume "root" created.
  $ lvcreate -L 20G -n swap vpool
    Logical volume "swap" created.
  $ lvcreate -l 100%FREE -n home vpool
    Logical volume "home" created.
```

After creating the `swap` volume, Linux needs to know to use it as its swap space. You can do so using `mkswap` and the new mapped drive path:

```sh
  $ mkswap /dev/vpool/swap
  Setting up swapspace version 1, size = 20 GiB (21474832384 bytes)
  no label, UUID=...
```

### Setting the filesystems


## Installing GRUB

## Display and Window Managers
