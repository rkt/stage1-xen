## stage1-xen Fedora Buildroot

stage1-xen build artifacts for Fedora is built in two phases. In the first phase
a docker container is prepared with all the build dependencies. We refer to it
as `stage1-xen-fedora-buildroot`. In the next phase we execute the `run` script
that uses `stage1-xen-fedora-buildroot` and to produce the build artifacts.

### Building `stage1-xen-fedora-buildroot`

`stage1-xen-fedora-buildroot` has a external dependency
on [`binutils`](https://github.com/lambda-linux-fedora/binutils) package that is
compiled with `i386pe` support. You can download the pre-built RPMs
from [here](https://drive.google.com/open?id=0B_tTbuxmuRzIR05wQ3E1eWVyaGs).
Please download `binutils-2.26.1-1.1.fc25.tar`.

To build docker image

```
cd stage1-xen/build/fedora

docker build -f buildroot-Dockerfile -t stage1-xen-fedora-buildroot .
```

### Running `stage1-xen-fedora-buildroot`

```
cd stage1-xen

docker run --rm \
  -v `pwd`:/root/gopath/src/github.com/rkt/stage1-xen \
  -v /tmp:/tmp \
  -t -i stage1-xen-fedora-buildroot \
  /sbin/my_init -- /root/bin/run
```

The generated build artifacts are in `/tmp` directory.

To debug build issues -

```
cd stage1-xen

docker run --rm \
  -v `pwd`:/root/gopath/src/github.com/rkt/stage1-xen \
  -v /tmp:/tmp \
  -t -i stage1-xen-fedora-buildroot \
  /sbin/my_init -- /bin/bash
```

Also see section on `ipdb` in `buildroot-Dockerfile`.
