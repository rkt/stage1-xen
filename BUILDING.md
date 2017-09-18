# Build
stage1-xen requires new Xen and QEMU versions at the time of writing. You are unlikely to find them already packaged with your distro. This document describes how to build and install the latest Xen, QEMU and rkt from scratch for Ubuntu Xenial Xerus and Fedora. Differently from documentation for Ubuntu, the documentation for Fedora uses a Docker container for the build. There is also support for building on host on Fedora.

 * [Ubuntu Xenial Xerus](#build_ubuntu)
 * [Fedora](#build_fedora)

<a name="build_ubuntu"></a>
## Ubuntu Xenial Xerus

### Building Xen
```
apt-get install git build-essential python-dev gettext uuid-dev libncurses5-dev libyajl-dev libaio-dev pkg-config libglib2.0-dev libssl-dev libpixman-1-dev bridge-utils wget libfdt-dev bin86 bcc liblzma-dev iasl libc6-dev-i386

git clone git://xenbits.xen.org/xen.git
cd xen
./configure --prefix=/usr --with-system-qemu=/usr/lib/xen/bin/qemu-system-i386 --disable-stubdom --disable-qemu-traditional --disable-rombios
make -j4
make install
update-rc.d xencommons defaults
update-grub
reboot
```
Make sure to select Xen at boot, or edit /boot/grub/grub.cfg to make it the default, changing "set default="0" to point to the appropriate entry below (the one booting xen.gz), which could be entry number "4" for example.


### Building QEMU
```
apt-get install libglib2.0-dev libpixman-1-dev libcap-dev libattr1-dev

git clone git://git.qemu.org/qemu.git
export DIR=/home/username/xen
cd qemu
./configure --enable-xen --target-list=i386-softmmu \
                --extra-cflags="-I$DIR/tools/include \
                -I$DIR/tools/libs/toollog/include \
                -I$DIR/tools/libs/evtchn/include \
                -I$DIR/tools/libs/gnttab/include \
                -I$DIR/tools/libs/foreignmemory/include \
                -I$DIR/tools/libs/devicemodel/include \
                -I$DIR/tools/libxc/include \
                -I$DIR/tools/xenstore/include \
                -I$DIR/tools/xenstore/compat/include" \
                --extra-ldflags="-L$DIR/tools/libxc \
                -L$DIR/tools/xenstore \
                -L$DIR/tools/libs/evtchn \
                -L$DIR/tools/libs/gnttab \
                -L$DIR/tools/libs/foreignmemory \
                -L$DIR/tools/libs/call \
                -L$DIR/tools/libs/devicemodel \
                -Wl,-rpath-link=$DIR/tools/libs/toollog \
                -Wl,-rpath-link=$DIR/tools/libs/evtchn \
                -Wl,-rpath-link=$DIR/tools/libs/gnttab \
                -Wl,-rpath-link=$DIR/tools/libs/call \
                -Wl,-rpath-link=$DIR/tools/libs/foreignmemory \
                -Wl,-rpath-link=$DIR/tools/libs/call \
                -Wl,-rpath-link=$DIR/tools/libs/devicemodel" \
                --disable-kvm --enable-virtfs
make -j4
make install
cp i386-softmmu/qemu-system-i386 /usr/lib/xen/bin/
```

### Building CoreOS rkt
```
apt-get install golang automake libacl1-dev libsystemd-dev
./configure --disable-tpm --with-stage1-flavors=coreos
make
cp build-rkt-1.26.0+git/target/bin/rkt /usr/sbin
```

### Building stage1-xen
```
apt-get install busybox-static jq

git clone https://github.com/rkt/stage1-xen.git
cd stage1-xen
export GOPATH=/path/to/gopath
bash build.sh
cp stage1-xen.aci /home/username
```

<a name="build_fedora"></a>
## Fedora

On Fedora there are two ways to build stage1-xen artifacts.

 * [Container Build](#build_fedora_container_build)
 * [Manual Build](#build_fedora_manual_build)

<a name="build_fedora_container_build"></a>
### Container Build

We can build stage1-xen artifacts (Xen, QEMU and rkt) automatically in a docker container as follows &ndash;

```
cd stage1-xen

docker pull lambdalinuxfedora/stage1-xen-fedora-buildroot

docker run --rm \
  -v `pwd`:/root/gopath/src/github.com/rkt/stage1-xen \
  -v /tmp:/tmp \
  -t -i lambdalinuxfedora/stage1-xen-fedora-buildroot \
  /sbin/my_init -- /root/bin/run
```

Once `docker run` completes, the build artifact `stage1-xen-build.tar.gz` is generated in `/tmp` directory. Please see [RUNNING_STAGE1_XEN.md](build/fedora/RUNNING_STAGE1_XEN.md) for details on how to setup Fedora for running stage1-xen.

<a name="build_fedora_manual_build"></a>
### Manual Build

It is also possible to manually build stage1-xen components on a Fedora host. 

Please ensure that you have all the dependencies installed. The dependencies for Xen, QEMU, rkt and stage1-xen is documented in [buildroot-Dockerfile](build/fedora/buildroot-Dockerfile). You will also need to install [`binutils`](https://github.com/lambda-linux-fedora/binutils) package that is compiled with `i386pe` support. You can download the pre-built RPMs from [here](https://drive.google.com/open?id=0B_tTbuxmuRzIR05wQ3E1eWVyaGs).

Install `binutils` package.

```
tar xvf binutils-2.26.1-1.1.fc25.tar

dnf install -y ./binutils/2.26.1/1.1.fc25/x86_64/binutils-2.26.1-1.1.fc25.x86_64.rpm
```

You can verify `i386pe` support in `binutils` by doing the following.

```
[root@localhost]# ld -V
GNU ld version 2.26.1-1.1.fc25  Supported emulations:
   elf_x86_64
   elf32_x86_64
   elf_i386
   elf_iamcu
   i386linux
   elf_l1om
   elf_k1om
   i386pep
   i386pe
```

You should see the lines `i386pep` and `i386pe` in the output.

Next you can build Xen, Qemu and rkt using the following scripts &ndash;

 * [`build/fedora/components/xen`](build/fedora/components/xen)
 * [`build/fedora/components/qemu`](build/fedora/components/qemu)
 * [`build/fedora/components/rkt`](build/fedora/components/rkt)

Please review the scripts and adjust the paths according to your requirements.

Once the dependencies are installed, you can build stage1-xen

```
git clone https://github.com/rkt/stage1-xen.git
cd stage1-xen
export GOPATH=/path/to/gopath
bash build.sh
cp stage1-xen.aci /home/username
```

Please see [RUNNING_STAGE1_XEN.md](build/fedora/RUNNING_STAGE1_XEN.md) for details on how to run rkt with stage1-xen.
