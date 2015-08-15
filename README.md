# make-vm [![License](https://img.shields.io/github/license/joebiellik/make-vm.svg)](LICENSE.md)

Simple [Makefile](https://www.gnu.org/software/make/) script for quickly generating [KVM](http://www.linux-kvm.org/) virtual machine images for [libvirt](https://libvirt.org/). Designed for and tested on [CentOS](https://www.centos.org/) 6.

Requires
--------
* [python-virtinst](https://git.fedorahosted.org/git/python-virtinst.git) (virt-install)
* [libguestfs-tools](http://libguestfs.org/) (virt-resize)

Usage
-----
```sh
# The default command will build a new gold card image for cloning
make
# or specify a custom kickstart script
make KS=custom.ks

# You can then quickly make a cloned image
make clone NAME=test VCPU=4 RAM=4096
# You can run a custom shell script on first boot
make clone NAME=database FB=install_mysql.sh

# Destroy the base image
make clean
```

Have a look at [the source](Makefile#L3-L27) to see all the available configuration options.
