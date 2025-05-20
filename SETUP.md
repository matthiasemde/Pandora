# Basic Setup
## Connect to BMC
Find the BMC ip address in your router and access it via the browser.
Login using username "admin" and the password printed on the board.

## Install NixOS
Download the minimal image from [nixos.org](https://nixos.org/download/).

Start KVM and mount the .iso file as a virtual CD.
Then reboot and select the virtual CD as boot device in the BIOS.

I am following [this](https://www.youtube.com/watch?v=lUB2rwDUm5A) guide to set up NixOS ([here](https://nixos.org/manual/nixos/stable/#ch-installation) is the written form)

First of switch into sudo mode
```bash
$ sudo -i
```

Set keyboard layout to german using.
```
# loadkeys de
```

Look at the drives using
```
# lsblk
```
and note the name of your main drive. In my case 'nvme0n1'.

Start cfdisk with
```
# cfdisk /dev/nvme0n1
```
and create at least the following partitions:
* 1G -> type: 'EFI System' (boot partition)
* 4G -> type: 'Linux swap' (swap partition)
* ~256G -> type: 'Linux filesystem' (system partition)
* rest -> type: 'Linux filesystem' (data partition)

Select [write] and confirm. Then quit cfdisk.

Now we name the partitions
```
# lsblk
# mkfs.ext4 -L persistent /dev/nvme0n1p4
# mkfs.ext4 -L nixos /dev/nvme0n1p3
# mkswap -L swap /dev/nvme0n1p2
# mkfs.fat -F 32 -n boot /dev/nvme0n1p1
```

Then mount all the drives
```
# mount /dev/nvme0n1p3 /mnt
# mount --mkdir /dev/nvme0n1p1 /mnt/boot
# swapon /dev/nvme0n1p2
# mount -t efivarfs efivarfs /sys/firmware/efi/efivars
# lsblk (to verify)
```

The command nixos-generate-config can generate an initial configuration file for you:
```
# nixos-generate-config --root /mnt
# vim /mnt/etc/nixos/configuration.**nix**
```

Change locale, keyboard layout and add git to the list of packages.

```
# nixos-install
```

Enter root password.

```
# nixos-enter --root /mnt -c 'passwd myuser'
```
Set user password.

Reboot and log in as user.

## Install this project

Clone the repo into your home directory.
```
$ git clone ...
```

Build using
```
$ nixos-rebuild switch --flake .#mahler
```

and `reboot` again.
