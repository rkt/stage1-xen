# Running Stage1 Xen on Fedora

This document outlines the steps to get started with stage1-xen on Fedora. They are &ndash;

 * [Preparing your machine and installing minimal Fedora](#preparing_your_machine_and_installing_minimal_fedora)
 * [Booting into Xen](#booting_into_xen)
 * [Launching Xen services](#launching_xen_services)
 * [Setting up Xen networking](#setting_up_xen_networking)
 * [Running stage1-xen](#running_stage1-xen)

<a name="preparing_your_machine_and_installing_minimal_fedora"></a>
## Preparing your machine and installing minimal Fedora

On x86 platform there are two ways to start an operating system or a hypervisor. They are &ndash;

 * Legacy BIOS Mode
 * EFI Mode

Latest operating systems and hypervisors including Fedora and Xen has support for EFI mode. If you are unfamiliar with EFI we recommend checking out this [article](http://www.rodsbooks.com/efi-bootloaders/principles.html).

By default, most BIOS now boot using EFI Mode. In your BIOS menu, there might be an option to toggle _Legacy BIOS Mode_. Do not toggle that option.

### Enable VT-x and VT-d

Please ensure that you have enabled VT-x and if available VT-d.

### Disable Secure Boot

As we will be booting a custom build of Xen, we need to disable secure boot. You will find an option in your BIOS menu to disable secure boot.

### Installing minimal Fedora

The default Fedora installation installs packages that we do not require when running Xen. We recommend doing a minimal Fedora as follows.

 1. Download Net Install image

 2. Prepare a USB drive

 3. Do a minimal Fedora Install

You can download the Fedora net install image [here](https://alt.fedoraproject.org/). You can select either the Fedora Server or Fedora Workstation image, it doesn't really matter.

After downloading the net install images, please copy the raw image onto a USB drive. Please see [this](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-making-usb-media.html) link on how to prepare USB drive.

EFI BIOS comes with a _BIOS Boot Menu_ using which you can select the device to boot from. Insert the USB drive, then go into your BIOS Boot Menu and boot using the USB drive. This should start the Fedora Network Installer.

In the Fedora Installer, there is a section for under _SOFTWARE_ called _SOFTWARE SELECTION_. In this section please **select** either _Minimal Install_ or _Basic Desktop_, **without** any add-ons.

**Note:** If there is existing data on the hard disk, please ensure that _INSTALLATION DESTINATION_ under _SYSTEM_ section is appropriately configured.

Then click on _Begin Installation_ to complete the installation.

Once the installation is complete, please disable SELinux by editing `/etc/selinux/config`.

You now have a minimal Fedora Installation, which is good for working with Xen.

<a name="booting_into_xen"></a>
## Booting into Xen

Build and install Xen and stage1-xen. Please see [BUILDING.md](/BUILDING.md#build_fedora).

If you followed the container build with Docker, then copy over `stage1-xen-build.tar.gz`. Extract `stage1-xen-build.tar.gz` into `/opt` directory.

```shell
[root@localhost ~]# tar zxvf stage1-xen-build.tar.gz -C /opt

[root@localhost ~]# ls /opt
qemu-2.10.0  stage1-xen  xen-4.9.0  xen-4.9.0-runit
```

This will extract all the build artifacts into `/opt` directory.

Next we will create a BIOS Boot Menu entry to boot `xen-4.9.0.efi`. This will start Xen hypervisor. Xen will then start Fedora as Dom-0 guest.

On Fedora, EFI system partition (ESP) is usually mounted at `/boot/efi`. This is a `vfat` partition. You can check if EFI system partition is mounted as follows &ndash;

```shell
[root@localhost ~]# mount | grep '\/boot\/efi'
/dev/sda1 on /boot/efi type vfat (rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=ascii,shortname=winnt,errors=remount-ro)
```

Create a directory for Xen under `/boot/efi/EFI` and copy over `xen-4.9.0.efi`.

```shell
[root@localhost ~]# mkdir -p /boot/efi/EFI/xen
[root@localhost ~]# cp /opt/xen-4.9.0/boot/efi/EFI/xen/xen-4.9.0.efi /boot/efi/EFI/xen/
```

Inspect `/boot/efi/EFI/fedora/grub.cfg`. Under section `### BEGIN /etc/grub.d/10_linux ###` you will find `menuentry` for Fedora kernel and initrd. Look for `linuxefi` and `initrdefi`. Copy over the `vmlinuz` and `initramfs` files that you want to use for your Dom-0 into `/boot/efi/EFI/xen` directory.

```shell
[root@localhost ~]# cp /boot/vmlinuz-A.B.C-D.fcXX.x86_64 /boot/efi/EFI/xen/

[root@localhost ~]# cp /boot/initramfs-A.B.C-D.fcXX.x86_64.img /boot/efi/EFI/xen/
```

Now in `/boot/efi/EFI/xen/` you should have the following files.

```shell
[root@localhost ~]# ls /boot/efi/EFI/xen/
initramfs-A.B.C-D.fcXX.x86_64.img  vmlinuz-A.B.C-D.fcXX.x86_64  xen-4.9.0.efi
```

Next create a file `xen-4.9.0.cfg` in `/boot/efi/EFI/xen/`. This is the [configuration file](https://xenbits.xen.org/docs/unstable/misc/efi.html) that Xen EFI loader will use to load Dom-0 kernel and initrd.

Following are contents of `xen-4.9.0.cfg`

```
[global]
default=fedora-A.B.C-D.fc25

[fedora-A.B.C-D.fc25]
options=console=vga,com1 com1=115200,8n1 iommu=verbose ucode=scan flask=disabled conring_size=2097152 loglvl=all autoballoon=0 dom0_mem=4096M,max:4096M
kernel=vmlinuz-A.B.C-D.fc25.x86_64 root=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ro rhgb console=hvc0 console=tty0
ramdisk=initramfs-A.B.C-D.fc25.x86_64.img
```

You can find the boot parameters for `kernel=` from `linuxefi` entry in `/boot/efi/EFI/fedora/grub.cfg` Adjust `dom0_mem` appropriately leaving sufficient room for dom-U guests.

We can now use `efibootmgr` to create a boot entry for Xen. If this the first time you are using `efibootmgr` please checkout the man pages by doing `man efibootmgr`.

Use `efibootmgr -v` to list all the EFI boot entires.

```shell
[root@localhost ~]# efibootmgr -v
BootCurrent: 0002
Timeout: 2 seconds
BootOrder: ...

[...]

Boot0001* Xen   HD(1,GPT,7d511991-1c25-4e33-900b-1d61d7752f19,0x800,0x82000)/File(\EFI\xen\xen-4.9.0.efi)
Boot0002* Fedora        HD(1,GPT,7d511991-1c25-4e33-900b-1d61d7752f19,0x800,0x82000)/File(\EFI\fedora\shim.efi)

[...]
```

In the above example there is already an entry for Xen with a boot number of `1`. Fedora is at boot number `2`. Your entires would look different. You won't have the Xen entry as yet! We are showing you an example where the Xen boot entry has already been created.

Let us now create a boot entry for Xen. First we need to identify the disk and the partition number for EFI system partition. In most cases it is at `/dev/sda1`. You can identify this by doing &ndash;

```shell
[root@localhost ~]# df /boot/efi
Filesystem     1K-blocks  Used Available Use% Mounted on
/dev/sda1         262128 63019    199109  25% /boot/efi

[root@localhost ~]# sgdisk -p /dev/sda
Disk /dev/sda: 976773168 sectors, 465.8 GiB
Logical sector size: 512 bytes

[...]

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048          534527   260.0 MiB   EF00  EFI System Partition
```

You can now create boot entry for Xen using the following command. Adjust `/dev/sda` and `-p 1`, according to where your EFI system partition is located.

```shell
[root@localhost ~]# efibootmgr -c -w -L Xen -d /dev/sda -p 1 -l '\EFI\xen\xen-4.10-unstable.efi'
BootCurrent: ...
Timeout: 2 seconds
BootOrder: 0001,0002,0000,0010,0011,0012,0013,0017,0018,0019,001A,001B,001C

[...]

Boot0002* Fedora

[...]

Boot0001* Xen
```

The output indicates that a boot entry for Xen is created with a boot number of `1`. 

We will now show you how to delete an existing boot entry.

**Note:** Be careful when deleting boot entires that you have not created. Do not delete Fedora or any entry unless you really know what you are doing. You have been warned!

```shell
[root@localhost ~]# efibootmgr -b <boot_num> -B

[root@localhost ~]# efibootmgr -b 1 -B
BootCurrent: ...
BootOrder: ...

[...]

Boot0002* Fedora
Boot0010  Setup

[...]
```

Once we have created a boot entry we can now boot into Xen. Restart machine and from the BIOS boot menu select **Xen**. You'll see Xen starting followed by Linux.

After booting into Linux, you can see if have successfully booted Xen by checking out `dmesg`.

```shell
[root@localhost ~]# dmesg | grep [Xx]en
[    0.000000] Xen: [mem 0x0000000000000000-0x0000000000057fff] usable

[...]

[    0.000000] Hypervisor detected: Xen
[    0.000000] Setting APIC routing to Xen PV.
[    0.000000] Booting paravirtualized kernel on Xen
[    0.000000] Xen version: 4.9.0 (preserve-AD)
[    0.001000] Xen: using vcpuop timer interface
[    0.001000] installing Xen timer for CPU 0
```

If you don't see Xen mentioned in your `dmesg`, then please check the previous steps.

<a name="launching_xen_services"></a>
## Launching Xen services

In Dom-0, we need to launch services required by Xen. If you followed the manual build, please make sure that xencommons init script has been started at boot.

For container build you can use [`runit`](http://smarden.org/runit/) process supervisor. You can download and install `runit` RPMs for Fedora from [here](https://drive.google.com/open?id=0B_tTbuxmuRzIR05wQ3E1eWVyaGs).

```shell
(ensure correct checksum on the downloaded binary)
[root@localhost ~]# echo "10cc62ffc040c49efa0dd85cbacd70c0712a7c10c58717a376610b786bc49d19  runit-2.1.2-1.1.fc25.tar" | sha256sum -c -
runit-2.1.2-1.1.fc25.tar: OK

[root@localhost ~]# tar xvf runit-2.1.2-1.1.fc25.tar

[root@localhost ~]# dnf install -y ./runit/2.1.2/1.1.fc25/x86_64/runit-2.1.2-1.1.fc25.x86_64.rpm

[root@localhost ~]# pgrep -af runsvdir
1679 runsvdir -P -H /etc/service log: ..........................................................
```

In `/opt/xen-4.9.0-runit` we provide two scripts to manage Xen services. 

 * `setup.sh`
 * `teardown.sh`

`setup.sh` is used to setup Xen services. If you are going to be running Fedora directly without Xen, please use `teardown.sh` prior to shutting down Domain-0. This will disable launching Xen services under Fedora without Xen.

Run `setup.sh`

```shell
[root@localhost ~]# /opt/xen-4.9.0-runit/setup.sh
Successfully created symlinks in /etc/service directory.
```

You can verify Xen services are running correctly by doing the following &ndash;

```shell
[root@localhost ~]# ls /etc/service | xargs -L 1 -I {} sv status {}
run: xenconsoled: (pid 29673) 115s
run: xen-init-dom0: (pid 29672) 115s
run: xen-init-dom0-disk-backend: (pid 29675) 115s
run: xenstored: (pid 29674) 115s

[root@localhost ~]# source /opt/stage1-xen/bin/source_path.sh

[root@localhost ~]# xl info
host                   : localhost.localdomain
release                : 4.11.12-200.fc25.x86_64
version                : #1 SMP Fri Jul 21 16:41:43 UTC 2017
machine                : x86_64

[...]

cc_compile_domain      : [unknown]
cc_compile_date        : Fri Aug 18 06:32:55 UTC 2017
build_id               : 4a65e1ae96407a8dd47f318db4bdf7d3
xend_config_format     : 4

[root@localhost ~]# xl list
Name                                        ID   Mem VCPUs      State   Time(s)
Domain-0                                     0  4096     4     r-----     121.2
```

<a name="setting_up_xen_networking"></a>
## Setting up Xen networking

There are multiple ways to do networking on Xen. Two common configurations are [bridging](https://wiki.xenproject.org/wiki/Xen_Networking#Bridging) and [NAT](https://wiki.xenproject.org/wiki/Xen_Networking#Network_Address_Translation). Bridging is the default and most simple configuration to setup. However wireless device drivers are unable to do bridging. To overcome this limitation, we setup an internal  bridge and then use NAT to send packets externally. This setup works for both wired and wireless devices.

```shell
[root@localhost ~]# ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s31f6: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN mode DEFAULT group default qlen 1000
    link/ether c8:5b:76:71:40:c8 brd ff:ff:ff:ff:ff:f
3: wlp4s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT group default qlen 1000
    link/ether e4:a7:a0:93:9f:13 brd ff:ff:ff:ff:ff:f
```

We have two devices `enp0s31f6` which is a wired ethernet device and `wlp4s0` which is a wireless ethernet device. We will use `wlp4s0` in the following example. However similar approach would also work for `enp0s31f6` device. You can also adjust the private network 10.1.1.0/24 to a non-overlapping private subnet. 

```shell
[root@localhost ~]# brctl show
bridge name     bridge id               STP enabled     interfaces

[root@localhost ~]# ip link add xenbr0 type bridge

[root@localhost ~]# ip addr add 10.1.1.1/24 dev xenbr0

[root@localhost ~]# ip link set xenbr0 up

[root@localhost ~]# modprobe dummy

[root@localhost ~]# ip link set dummy0 up

[root@localhost ~]# brctl addif xenbr0 dummy0

[root@localhost ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
xenbr0          8000.d21b5c4113b7       no              dummy0

[root@localhost ~]# iptables -I FORWARD -j ACCEPT

[root@localhost ~]# iptables -t nat -I POSTROUTING --out-interface wlp4s0 -j MASQUERADE

[root@localhost ~]# echo 1 > /proc/sys/net/ipv4/ip_forward
```

With this configuration we can launch Dom-U Xen guests using the following configuration setting.

```
# Network configuration
vif = ['bridge=xenbr0']
```

Then from within the guest, we will need to setup `eth0` interface with a static IP address in the range of 10.1.1.0/24 and gateway as 10.1.1.1.

<a name="running_stage1-xen"></a>
## Running stage1-xen

Once we have Xen setup, it is fairly straightforward to run stage1-xen.

If you followed manual build, then please ensure that you have `xl` and `rkt` in your path.

For container build, we provide a script to source all the required binaries from Xen, QEMU and rkt into our path.

```shell
[root@localhost ~]# source /opt/stage1-xen/bin/source_path.sh
```

We can now download images using `rkt` and run them under stage1-xenbits

```shell
[root@localhost ~]# rkt --insecure-options=image fetch docker://alpine
Downloading sha256:88286f41530 [=============================] 1.99 MB / 1.99 MB
sha512-f84f971f8e01284f4ad0c3cf3efaa770

[root@localhost ~]# rkt run sha512-f84f971f8e01284f4ad0c3cf3efaa770 \
                      --interactive --insecure-options=image \
                      --stage1-path=/opt/stage1-xen/aci/stage1-xen.aci
```

Within the container, we can see we are running as a Xen PV guest, and using 9pfs

```shell
/ # dmesg | grep [Xx]en
[    0.000000] Xen: [mem 0x0000000000000000-0x000000000009ffff] usable
[    0.000000] Xen: [mem 0x00000000000a0000-0x00000000000fffff] reserved
[    0.000000] Xen: [mem 0x0000000000100000-0x000000003fffffff] usable
[    0.000000] Hypervisor detected: Xen
[    0.000000] Booting paravirtualized kernel on Xen
[    0.000000] Xen version: 4.9.0 (preserve-AD)
[    0.000000] xen:events: Using FIFO-based ABI

[...]

[    1.605990] Initialising Xen transport for 9pfs
```

From Domain-0, we can run `rkt` and `xl` to get the details of the container.

```shell
[root@localhost ~]# rkt list
UUID            APP     IMAGE NAME                                      STATE   CREATED       STARTED          NETWORKS
222083ec        alpine  registry-1.docker.io/library/alpine:latest      running 4 minutes ago 4 minutes ago    default:ip4=172.16.28.15

[root@localhost ~]# xl list
Name                                        ID   Mem VCPUs      State   Time(s)
Domain-0                                     0  4093     4     r-----    1056.9
222083ec-d6da-4347-b261-0a733bae6802         1  1024     2     -b----       2.2

[root@localhost ~]# rkt stop 222083ec
"222083ec-d6da-4347-b261-0a733bae6802"

[root@localhost ~]# xl list
Name                                        ID   Mem VCPUs      State   Time(s)
Domain-0                                     0  4093     4     r-----    1058.5
```
