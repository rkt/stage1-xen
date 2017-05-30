# stage1-xen - A Xen based stage1 for CoreOS rkt

## Goal

CoreOS rkt is a modular container engine with [three stages of execution](https://coreos.com/rkt/docs/latest/devel/stage1-implementors-guide.html). Stage1 is responsible for creating the execution environment for the contained applications.

Stage1s come in the form of [ACI](https://github.com/appc/spec) images, and they can be user-provided. For example, the following option allows the user to specify a different stage1 from the command line:
```
  rkt --stage1-path=/path/to/stage1-xen.aci
```
This project aims at providing a new stage1 based on the Xen hypervisor. Each [pod](https://coreos.com/rkt/docs/latest/subcommands/run.html#run-multiple-applications-in-the-same-pod) (a small set of contained applications) is run in a separated Xen virtual machine. On x86 PV and PVH virtual machines are used, depending on the availability of hardware virtualization support.


## Build and Output

Make sure to have all the dependencies installed, see [DEPENDENCIES]. Xen needs to be at least version 4.9. Then, execute *build.sh*. The output is the file *stage1-xen.aci*, which is the stage1 ACI image. stage1-xen.aci does not contain any Xen binaries itself, it relies on *xl* being available on the host.
