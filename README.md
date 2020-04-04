# dotfiles-arch

## Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Disk setup](#disk-setup)
4. [GRUB installation](#installing-grub)
5. [Display/Window managers](#display-and-window-managers)

## Overview
This repoistory contains the dotfiles for my Arch Linux installation, as well as a step-by-step guide on how to install Arch Linux from scratch on a duel-booted machine. It assumes you have a working knowledge of UNIX and a functional knowledge of basic GNU and CLI utilities. **There are many different ways you can choose to setup your own machine and I am not claiming that my way is the best way for you. Several factors have gone into the procedure outlined below, so if it does not fit your beliefs or needs simply don't follow it to the tee.**

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
You will need to connect to the internet to successfully complete installation. To connect to Wi-Fi, run the following command. It will poll for avaliable devices and networks, and then open a UI prompting you to select a network and enter its connection credentials.

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

### Setting the filesystems
Now that the logical volumes have been made, we need to "install" the appopriate filesystems onto each of them. I opt for ext4 (https://en.wikipedia.org/wiki/Ext4), as it is allegedly faster and can support larger filesizes, but ext3 (https://en.wikipedia.org/wiki/Ext3) works just as well (and perhaps even more stably).

```sh
  $ mkfs.ext4 /dev/vpool/root
  mke2fs 1.45.5 (07-Jan-2020)
  Discarding device blocks: done
  ...
  Writing superblocks and filesystem accounting information: done
  
  $ mkfs.ext4 /dev/vpool/home
  mke2fs 1.45.5 (07-Jan-2020)
  Discarding device blocks: done
  ...
  Writing superblocks and filesystem accounting information: done
```

#### Swap
Swap is tricky, as it has a specialized file structure different from standards like ext4 and ext2. The process is, however, no more complicated:

```sh
  $ mkswap /dev/vpool/swap
  Setting up swapspace version 1, size = 20 GiB (21474832384 bytes)
  no label, UUID=...
```

## Installing the Essentials
You now have fully functional logical volumes to use with Arch Linux. Congratulations! Now we can mount the drive, install the Linux kernel, device firmware, and the other utilities deemed essential for function. We can do both of those with the beloved `mount` and `pacstrap` command, which will download and install all the provided packages and package groups to the specified drive location.

### Creating a better mirrorlist
The order of your mirrorlist, which is simply the list of URLs from which `pacman` can download packages, can be a major problem. If you choose to ignore the mirrorlist and just go on installing Arch, you might find that `pacman` downloads are painfully slow. By default, the `pacman` mirrorlist contains a huge number of possible servers, but they might not be ordered best for your location and country. Thankfully, someone thought of this problem and created the `reflector` package, which essentially pings a list of known mirrors in your country and orders them by download speed. That way, we can be sure we're using the most up-to-date mirrors in the best possible order.

```sh
  $ pacman -Syy
  $ pacman -S reflector
```

As a saftey precaution, it is generally always a good idea to make a backup of critical files before modifying them. In this case, we want to make a backup of `/etc/pacman.d/mirrorlist` before we overwrite it. Then we can continue and create our new mirrorlist, making sure to update the country for your location:

```sh
  $ cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old
  $ reflector -c US -f 12 -l 12 --sort rate --protocol https --protocol http --threads $(nproc) --verbose --save /etc/pacman.d/mirrorlist
  /root.cache/mirrorstatus.json
  ...
```

### Mounting and installing
Now we need to make sure we mount all the volumes on which we intend to write and save data. If we don't, we might end up installing critical files to locations that will get overwritten later. **This is bad - I can speak from experience.** Once done, we can continue and actuall install the Arch essential packages (plus a few) to your new system.

```sh
  $ mount /dev/vpool/root /mnt
  $ mkdir /mnt/home /mnt/boot
  $ mount /dev/vpool/home /mnt/home
  $ mount /dev/nvme0n1p2 /mnt/boot
  $ swapon /dev/vpool/swap
  $ pacstrap /mnt base linux linux-firmware lvm2 neovim
```

The latter command, depending on your internet speed, might take a while to complete. Sit back, relax, and have a drink.

## Preparing your System
To make you life easier, we can tell Linux to automatically mount all of our drives every time we boot into Arch. That way, we can avoid having to manually mount your drives every time we want to do something. Linux makes use of a filed called `fstab` to autoremount drives at startup. Rather than manually listing our desired drives, we can export the current mount configuration directly to that file using `genfstab`. Since we had to mount all your drives to install the essentials above, we can simply export the current configuration.

```sh
  $ genfstab -U /mnt >> /mnt/etc/fstab
```

Once we've done that, we can `chroot` directly into our new installation. `chroot` changes the current working root directory from one folder to another. While this does not alter the programs that are currently running in the background (like `netctl`, which we started using `wifi-menu`), it ensures that any future changes we make to the filesystem will be relative to the new root rather than the current root (which is on our bootable ISO USB). In effect, any changes we make to your system after `chroot`-ing will be made to your permanent installation.

```sh
  $ arch-chroot /mnt
```

At this point, it's a good idea to tell your OS what language you will be working in. I natively speak American English, so that is the lanuage my system is set to use. However, you can enable and disable any of the default locales and languages depending on what you speak and prefer. Generally locale codes follow the format `language[_territory][.codeset]`, where `language` is an ISO 639-1 code (https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes), `territory` is an ISO 3166 country code (https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes), and `codeset` is a character encoding scheme.

My system is configured to use American English encoded using UTF-8. Following the format above that translates to `en_US.UTF-8`, where `en` stands for "English", `US` stands for "United States", and `UTF-8` stands for itself. In order to change your own system's locale, you can simply edit the `/etc/locale.gen` file and uncomment whichever locale you desire. Once you've done that, you can regenerate all your system's text using `locale-gen`.

```sh
  $ nvim /etc/locale.gen
  $ locale-gen
  Generating locales...
    en_US.UTF-8... done
  Generation complete.
```

### Generating initial ramdisks

> **The descriptions below are a large simiplication of a very complex and interconnected system. They are likely not 100% factual and thus serve only as a proxy for high-level understanding.**

A key step in the boot cycle for any operating system involves loading programs and files necessary for the kernel to function. Without those files, the OS kernel might not have the knowledge or access to the resources required to load critical information from disk. On Linux, for example, hardware device drivers and information are needed to find, and then load, the root `/` filesystem. Rather than manually coding a myriad of special cases into the generically-distributed Linux kernel, each installation creates an "early user space" that contains all the information about your environment's setup so that the kernel can successfully load your system's root filesystem. If you'd like to know more, I recommend reading the Wikipedia article on the Linux startup process (https://en.wikipedia.org/wiki/Linux_startup_process) and the initial ramdisk scheme (https://en.wikipedia.org/wiki/Initial_ramdisk).

On your machine, `mkinitcpio` is responsible for generating the initial ramdisk files for your system. Whenever the Linux kernel or other essential packages are updated, it regenerates the required boot files. As we setup your system to make use of LVM, your root filesystem is located on an a logical volume that is not directly readable by your kernel. As you can imagine, this means that in order for the kernel to mount your root directory your "early user space" needs to know how to navigate the LVM directory structure. Fortunately, all of that information is packaged into a loading "module", which can be injected into your "early user space". To enable the LVM module, we need to edit the `mkinitcpio` configuration file and include the `lvm2` module between the `block` and `filesystem` entries on the `HOOKS` line.

```sh
  $ nvim /etc/mkinitcpio.conf
  
  --------
  
  HOOKS=(base udev ... block lvm2 filesystems)
```

To more efficiently use your disk space, you can also enable compression of the generated files. This step is optional, but I recommend it if you are low of usable disk space. The method with the highest compression ratio is `xz`, which is an implementation of the LZMA2 compression algorithm. To enable it, simply uncomment `COMPRESSION=xz` and uncomment `COMPRESSION_OPTIONS` while `-e` to the list. 

Finally, regenrate your `initramfs` files by running `mkinitcpio -P`.

## Installing GRUB
In order to boot into your installation, you need a boot loader. A boot loader is what is found by your computer's BIOS or UEFI on startup, and is what points your computer to OS loading files. I recommend GRUB 2 because is easy to setup, customizable, and versatile, but there are many other options you can choose from if you so desire (https://en.wikipedia.org/wiki/Comparison_of_boot_loaders). The installation procedure is different depending on if your system is BIOS-based or UEFI-based, so follow the options for your system:

### BIOS-based
**NOTE: Remember to change the drive containing your boot system, as it is very unlikely to be `/dev/nvme0n2`.**

```sh
  $ pacman -S grub os-prober
  $ grub-install --target=$(uname -m) --bootload-id="Arch Linux" /dev/nvme0n2
```

### UEFI-based

```sh
  $ pacman -S grub efibootmgr os-prober  
  $ grub-install --target=$(uname -m)-efi --efi-directory=/boot --bootloader-id="Arch Linux"
```

After installing GRUB, you can configure it by editing the default configuration file via `nvim /etc/default/grub`. On my machine, I set `GRUB_TIMEOUT=-1` to prevent the autobooting into any OS. Besides any other configuration you do, make sure to add `lvm` to the end of `GRUB_PRELOAD_MODULES`.

While not necessary, I also recommend you install the proper microcode for your given system. Microcode is similar to CPU firmware, and is an abstraction above hardware-specific processs. Companies often release security patches and bug fixes to their CPUs' microcodes, so it is a good idea to install the latest release and allow GRUB to load it during boot time. As the microcode package you install differs depending on your physical system, I suggest you take a look at the official wiki page for more information (https://wiki.archlinux.org/index.php/Microcode). However, most systems will fall under one of the following two choices:

**Intel:** `pacman -S intel-ucode`

**AMD:** `pacman -S amd-ucode`

Finally, you just need to tell GRUB to regenerate it's startup script. It will automatically include your installed microcode package as well as any changes you made in `/etc/default/grub`.

```sh
  $ grub-mkconfig -o /boot/grub/grub.cfg
```

## Connecting to a Network
In my own personal and professional experience, managing networks and network connections is one of the most challenging technical infrastructure problems of the 21st century. For this very reason, I suggest using network managers that abstract away much of the complicated setup, protocol management, and device polling. There are many network managers avaliable, but the easiest I have found is GNOME's NetworkManager (https://wiki.archlinux.org/index.php/NetworkManager). Install it like anything other package, and then enable it using `systemd`.

```sh
  $ pacman -S networkmanager
  $ systemctl enable NetworkManager.service
```

For the changes to kick in, _**you need to restart your computer and boot into the new installation.**_ This is a critical step, as it is the first time yet that we're testing your installation. If it works, then we know that everything will work smoothly from here on out.

Assuming that you are now in the installation without the aid of the live USB, you can find and then connect to your desired network through the NetworkManager CLI. Once you connect, you can test the connection with `ping` like we did in the steps above.

```sh
  $ nmcli device wifi list
  $ nmcli device wifi connect _SSID_ password _password_
  $ ping 1.1.1.1
```

## Creating an Admin User
### Installing OpenDoas
If you are familar with UNIX systems, you have likely encountered the `sudo` command. At its core, `sudo` enables users to run processes with the security privleges of other users. However `sudo` comes with a lot of overhead an inefficiencies. For reaosns outlined in an initial blog post (https://flak.tedunangst.com/post/doas), I highly recommend `doas` instead. It is lightweight alternative to `sudo` and does 95% of what `sudo` does with a much smaller and efficient codebase. To install `doas`, install it like any other package:

```sh
  $ pacman -S opendoas
```

In order to setup your admin user correctly, you need to enable the `wheel` group. Users in the `wheel` group have, among other critical system privleges, the ability to run the `doas` command. `doas` is at its heart very configurable, so enabling the `wheel` group is fairly simple. For additional compatibility I also recommend symlinking `sudo` to `doas`, as there are many scripts and packages that assume `sudo` is a valid command on any Linux system. Without symlinking, I guarantee that many things that _should_ work will not (namely installing packages and dependencies with build hooks).

```sh
  $ echo "permit persist keepenv :wheel" > /etc/doas.conf
  $ ln -sv /usr/bin/doas /usr/bin/sudo
```

### Creating the user
Now that we've installed `doas`, creating a new system user with admin privleges is a trivial task. Beforehand, however, I highly suggest installing your preferred shell. I recommend `fish`:

> `fish` is a fully-equipped command line shell (like bash or zsh) that is smart and user-friendly. `fish` supports powerful features like syntax highlighting, autosuggestions, and tab completions that just work, with nothing to learn or configure. (https://fishshell.com/docs/current/tutorial.html)

For whichever shell you decide to use, be it `fish`, `zsh`, or `bash`, make sure to `-s` option in the `useradd` command to reflect the path to the corresponding executable. For reference, the `-s` flag specifies your new user's default shell and the last argument is the name of your new user. For me, that is `egabriel` (for Elias Gabriel).

At the same time, you need to specify the password for your new user. Because you're already logged in as `root`, you can simply change the password for your new user via the `passwd` command.

```sh
  $ useradd -m -G wheel -s /usr/bin/fish egabriel
  $ passwd egabriel
```

Finally, to ensure that any future command you run are running and installing things under your new user, make sure to switch your session:

```sh
  $ su egabriel
```

## Customization
Congratulations! If everything has working for you up until this point, which is by no means a gurantee, you have succssfully installed Arch Linux (have gotten smarter/more insane because of it). The next step is usually all about customization, so I will leave that up to your own research and preferences. If you're curious about my own setup, however, I encourage you to keep reading.

### Installing an AUR helper
If you're not aware, the Arch User Repository is one of the thing that makes Arch Linux and its ecosystem fantastic. In essence, the AUR is a community-driver package repository that hosts tons of packages and utilities outside of the ones officially distributed by the package databases. For the most part, you can find virtually any piece of software somewhere on the AUR, from Minecraft and Spotify to KiCad and MATLAB. The one challenge is that the AUR only hosts package build instructions, not prebuilt binaries.

This is where AUR helpers come into play. There are many to choose from, but fundementally they all do virtually the same thing: they automate the download and build process for AUR packages. When it comes to selecting them, I can really only say two things:

1. Definetly don't use `yaourt`. It's outdated, unmaintained, and has several security and functionality issues (https://github.com/archlinuxfr/yaourt/issues/382).
2. There will be pros and cons to whatever you choose, but realistically they're all going to do the same thing.

That being said, I searched around a lot for an AUR helper that filled my criteria. I wantd one that would wrap `pacman` for every package hosted on the official database and build every package from the AUR. Principally, however, I wanted one without tons of bloatcode and functionality that I would never use nor would ever find a use for. Those things combined, my search lead me to `pikaur` https://github.com/actionless/pikaur#pikaur.

To install it, you have to download and build it manually because all AUR helper packages are hosted on the AUR; this is what we're trying to avoid in the future.

```sh
  $ doas pacman -S fakeroot binutils make git gcc
  $ git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur
  $ cd /tmp/pikaur
  $ makepkg -fsri
```

Once you've done that, you can now install any official or AUR-hosted package simply using `pikaur` instead of `pacman`. From a CLI perspective, they're nearly identical (which was another criteria for my selection).

### Emulating my Environment
My personal machine is configured to run X11 with `bspwm` as a tiling window manager. If you want to download and play with my dotfiles, just install the required packages, clone this repo to your machine, and symlink the necessary files. **If you care about your machine's current config, please make sure to backup the `~/.config` directory and `~/.xinitrc` file in your home directory. I am not responsible for dataloss on behalf of your mistakes.**

```sh
  $ pikaur -S xorg-server xorg-xinit bspwm polybar rofi picom termite sxhkd otf-font-awesome
  $ git clone https://github.com/thearchitector/dotfiles-arch ~/.dotfiles
  $ ln -s ~/.config ~/.dotfiles/.config
  $ ln -s ~/.xinitrc ~/.dotfiles/.xinitrc
  $ startx
```
