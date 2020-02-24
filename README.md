## :warning: End of project :warning:

[![development](https://img.shields.io/badge/development-halted-red.svg)](https://github.com/rkt/rkt/issues/4024)

This project [has ended](https://github.com/rkt/rkt/issues/4024), and **all development/maintenance activities have halted**.

As it is free software, people are free and welcome to fork and develop the codebase on their own.
However, to avoid any confusion, the original repository is archived and we recommend any further fork/development to proceed with an explicit rename and rebranding first.

We encourage all interested parties to mirror any relevant bits as we can't actively guarantee their existence in the future.

---

# stage1-xen - A Xen based stage1 for CoreOS rkt

[![Build Status](https://circleci.com/gh/lambda-linux-fedora/stage1-xen/tree/wip2.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/lambda-linux-fedora/stage1-xen/tree/wip2)


## Goal

CoreOS rkt is a modular container engine with [three stages of execution](https://coreos.com/rkt/docs/latest/devel/stage1-implementors-guide.html). Stage1 is responsible for creating the execution environment for the contained applications.

Stage1s come in the form of [ACI](https://github.com/appc/spec) images, and they can be user-provided. For example, the following option allows the user to specify a different stage1 from the command line:
```
  rkt --stage1-path=/path/to/stage1-xen.aci
```
This project aims at providing a new stage1 based on the Xen hypervisor. Each [pod](https://coreos.com/rkt/docs/latest/subcommands/run.html#run-multiple-applications-in-the-same-pod) (a small set of contained applications) is run in a separated Xen virtual machine. On x86 PV and PVH virtual machines are used, depending on the availability of hardware virtualization support.

**Note:** stage1-xen is under active development. We encourage you to try stage1-xen and give us your feedback. However unlike upstream [Xen Project](https://wiki.xenproject.org/wiki/Xen_Project_Release_Features), we are still in _preview_ phase. So please do not expect _long term support_ or _backward compatibility_ as yet.

## Build and Output

See [BUILDING.md](BUILDING.md) for all the details. Make sure to have all the dependencies installed, see [DEPENDENCIES](DEPENDENCIES). Xen needs to be at least version 4.9. Then, execute **build.sh**. The output is the file **stage1-xen.aci**, which is the stage1 ACI image. stage1-xen.aci does not contain any Xen binaries itself, it relies on [xl](https://xenbits.xen.org/docs/unstable/man/xl.1.html) being available on the host.


## Usage

You can use stage1-xen by passing the appropriate --stage1-path option to rkt:
```
  rkt run sha512-b1dcf7bfa88f --interactive --insecure-options=image --stage1-path=/home/sstabellini/stage1-xen.aci
```
