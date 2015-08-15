install
url --url http://mirror.centos.org/centos/6/os/x86_64
repo --name updates --baseurl=http://mirror.centos.org/centos/6/updates/x86_64
repo --name extras --baseurl=http://mirror.centos.org/centos/6/extras/x86_64

unsupported_hardware

lang en_GB.UTF-8
keyboard uk
network --onboot yes --device eth0 --bootproto static --ip 192.168.0.100 --netmask 255.255.255.0 --gateway 192.168.0.1 --noipv6 --nameserver 8.8.8.8 --hostname kickstart
rootpw password
firewall --disabled
authconfig --enableshadow --passalgo=sha512
services --disabled=netfs,kdump,mdmonitor,ip6tables
selinux --disabled
timezone --utc UTC
bootloader --location=mbr --driveorder=vda --append="crashkernel=auto elevator=noop"

text
skipx
zerombr

clearpart --all --initlabel
part swap --size=512
part / --fstype=ext4 --grow --size=1024

auth --useshadow --enablemd5
firstboot --disabled
reboot

%packages --excludedocs --nobase
@core
acpid
wget
nano
-*firmware
-b43-openfwwf
-efibootmgr
-audit*
-libX*
-fontconfig
-freetype
-authconfig
-cronie
-postfix
-sudo
-vim-minimal
%end
