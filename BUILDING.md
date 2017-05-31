# Build
stage1-xen requires new Xen and QEMU versions at the time of writing. You are unlikely to find them already packaged with your distro. This document describes how to build and install the latest Xen and QEMU from scratch. In addition, given that CoreOS rkt is also missing from reasonably new distros such as Ubuntu Xenial Xerus, I added instructions on how to build that too. The document includes the dependencies needed for the build based on Ubuntu Xenial Xerus.

## Building Xen
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


## Building QEMU
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

## Building CoreOS rkt
```
apt-get install golang automake libacl1-dev libsystemd-dev
./configure --disable-tpm --with-stage1-flavors=coreos
make
cp build-rkt-1.26.0+git/target/bin/rkt /usr/sbin
```

## Building stage1-xen
```
apt-get install busybox-static jq

git clone https://github.com/rkt/stage1-xen.git
cd stage1-xen
export GOPATH=/path/to/gopath
bash build.sh
cp stage1-xen.aci /home/username
```
