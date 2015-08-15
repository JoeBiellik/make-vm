.PHONY: all gold clone clean

# global
OUTPUT = /var/lib/libvirt/images
GOLD_NAME = gold

# make & make clone
GOLD_SIZE = 10

# make
GOLD_VCPU = 2
GOLD_RAM = 2048
NETWORK = bridge:virbr0
MIRROR = http://mirror.centos.org/centos/6/os/x86_64
OS_VARIANT = rhel6
KS = centos.ks

# make clone
NAME = clone
SIZE = 25
VCPU = 4
RAM = 4096
DATA = data
DATA_SIZE = 0
DATA_DEV = vdb
DOMAIN = $(shell hostname -f)
FB = firstboot.sh

all: gold

gold: $(OUTPUT)/$(GOLD_NAME).qcow2
$(OUTPUT)/$(GOLD_NAME).qcow2:
	@echo `date +%H:%M:%S`: Creating new gold image...
	@echo `date +%H:%M:%S`: Building $(GOLD_SIZE)GB disk image...
	@fallocate -l `qemu-img create -f qcow2 -o preallocation=metadata $(OUTPUT)/$(GOLD_NAME).qcow2 $(GOLD_SIZE)G | cut -d' ' -f4 | cut -d'=' -f2` $(OUTPUT)/$(GOLD_NAME).qcow2
	@chmod 644 $(OUTPUT)/$(GOLD_NAME).qcow2
	@chown qemu:qemu $(OUTPUT)/$(GOLD_NAME).qcow2
	@echo `date +%H:%M:%S`: Assigning $(GOLD_VCPU) CPUs...
	@echo `date +%H:%M:%S`: Assigning $(GOLD_RAM)MB memory...
	@echo `date +%H:%M:%S`: Installing operating system...
	@virt-install \
		--name=$(GOLD_NAME) \
		--vcpus=$(GOLD_VCPU) \
		--ram=$(GOLD_RAM) \
		--graphics=none \
		--os-type=linux \
		--os-variant=$(OS_VARIANT) \
		--location=$(MIRROR) \
		--initrd-inject=./$(KS) \
		--extra-args="ks=file:/$(KS) console=ttyS0" \
		--disk path=$(OUTPUT)/$(GOLD_NAME).qcow2,bus=virtio,format=qcow2,sparse=false \
		--network=$(NETWORK) \
		--force --quiet --noautoconsole --wait=-1 --noreboot
	@echo `date +%H:%M:%S`: Install finished

clone: $(OUTPUT)/$(NAME).qcow2
$(OUTPUT)/$(NAME).qcow2: $(OUTPUT)/$(GOLD_NAME).qcow2
	@echo `date +%H:%M:%S`: Cloning gold image to \"$(NAME)\"...
ifeq ($(GOLD_SIZE),$(SIZE))
	@cp $(OUTPUT)/$(GOLD_NAME).qcow2 $(OUTPUT)/$(NAME).qcow2
else
	@echo `date +%H:%M:%S`: Resizing disk image to $(SIZE)GB...
	@qemu-img create -f qcow2 -o preallocation=metadata $(OUTPUT)/$(NAME).qcow2 $(SIZE)G >/dev/null
	@fallocate -l `stat -c "%s" $(OUTPUT)/$(NAME).qcow2` $(OUTPUT)/$(NAME).qcow2
	@virt-resize --quiet --expand /dev/sda2 $(OUTPUT)/$(GOLD_NAME).qcow2 $(OUTPUT)/$(NAME).qcow2
endif
	@chmod 644 $(OUTPUT)/$(NAME).qcow2
	@chown qemu:qemu $(OUTPUT)/$(NAME).qcow2
ifneq ($(DATA_SIZE),0)
	@echo `date +%H:%M:%S`: Creating $(DATA_SIZE)GB data disk \"$(DATA)\"...
	@qemu-img create -f raw $(OUTPUT)/$(NAME)-$(DATA).img $(DATA_SIZE)G >/dev/null
	@fallocate -l `stat -c "%s" $(OUTPUT)/$(NAME)-$(DATA).img` $(OUTPUT)/$(NAME)-$(DATA).img
	@mkfs.ext4 -q -I 512 -F $(OUTPUT)/$(NAME)-$(DATA).img
	@chmod 644 $(OUTPUT)/$(NAME)-$(DATA).img
	@chown qemu:qemu $(OUTPUT)/$(NAME)-$(DATA).img
endif
	@echo `date +%H:%M:%S`: Importing into libvirt...
	@virt-clone --force --original $(GOLD_NAME) --name $(NAME) --preserve-data --file $(OUTPUT)/$(NAME).qcow2 >/dev/null
	@echo `date +%H:%M:%S`: Assigning $(VCPU) CPUs...
	@virsh setvcpus $(NAME) $(VCPU) --config >/dev/null
	@echo `date +%H:%M:%S`: Assigning $(RAM)MB memory...
	@virsh setmaxmem $(NAME) $(RAM)MiB --config >/dev/null
ifneq ($(DATA_SIZE),0)
	@echo `date +%H:%M:%S`: Attaching disk \"$(DATA)\"...
	@virsh attach-disk $(NAME) $(OUTPUT)/$(NAME)-$(DATA).img $(DATA_DEV) --persistent >/dev/null
endif
	@echo `date +%H:%M:%S`: Preparing clone...
	@virt-sysprep \
		-d $(NAME) --quiet --no-selinux-relabel --hostname $(NAME).$(DOMAIN) --firstboot ./$(FB) \
		--enable ssh-hostkeys,udev-persistent-net,net-hostname,net-hwaddr,bash-history,utmp,tmp-files,logfiles,yum-uuid,package-manager-cache,hostname,firstboot
	@echo `date +%H:%M:%S`: Cloning finshed

clean:
	@virsh destroy $(GOLD_NAME) >/dev/null 2>&1 ; true
	@virsh undefine $(GOLD_NAME) >/dev/null 2>&1 ; true
	@rm -f $(OUTPUT)/$(GOLD_NAME).qcow2
