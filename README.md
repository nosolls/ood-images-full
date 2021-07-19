# What is this?

This is a demo for Open OnDemand. Forked it b/c the original demo doesn't seem to work anymore, and I'd like to mess with it.

# Setup

    git clone https://github.com/OSC/ood-images-full.git
    cd ood-images-full
    vagrant plugin install vagrant-vbguest

## Vagrant

Launch and setup the VMs:

    vagrant up head
    vagrant up ood

# Usage

Access to OpenOnDemand is via the `ood` user with password `ood`.

## Vagrant

Once the VM or container is online, the Open OnDemand interface can be accessed at localhost:8080

## VMware

The VM image defaults to use DHCP.  If DHCP is not setup for the imported VM, an IP must be set.  Below is an example.

    ip addr add <IP>/<NETMASK> dev eth0
    ip route add default via <GATEWAY>

The root password for the image is `ood`.

# Development

## Vagrant

