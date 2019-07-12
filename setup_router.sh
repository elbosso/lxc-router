#!/bin/bash
script=${0}
container=${1}
extdev=${2}
intdev=${3}
intaddress=${4}
intmask=${5}

echo "building container ${container}..."
lxc-create -t download -n ${container} -- -d ubuntu -r bionic  -a amd64

sed -i "s/lxc.net.0.link =.*/lxc.net.0.link = ${extdev}/g" /var/lib/lxc/${container}/config
echo "lxc.net.1.type = veth" >> /var/lib/lxc/${container}/config 
echo "lxc.net.1.link = ${intdev}" >> /var/lib/lxc/${container}/config
echo "lxc.net.1.flags = up" >> /var/lib/lxc/${container}/config


lxc-start -n ${container}

lxc-attach -n ${container} -- /bin/bash -c "echo '# ifupdown has been replaced by netplan(5) on this system.  See' > /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo '# /etc/netplan for current configuration.' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo '# To re-enable ifupdown on this system, you can run:' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo '#    sudo apt install ifupdown' >> /etc/network/interfaces"

lxc-attach -n ${container} -- /bin/bash -c "echo '# The loopback network interface' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo 'auto lo' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo 'iface lo inet loopback' >> /etc/network/interfaces"

lxc-attach -n ${container} -- /bin/bash -c "echo '# The primary network interface' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo 'auto eth0' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo 'iface eth0 inet dhcp' >> /etc/network/interfaces"

lxc-attach -n ${container} -- /bin/bash -c "echo 'auto eth1' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo 'iface eth1 inet static' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo '  address ${intaddress}' >> /etc/network/interfaces"
lxc-attach -n ${container} -- /bin/bash -c "echo '  netmask ${intmask}' >> /etc/network/interfaces"

lxc-attach -n ${container} -- apt-get -y remove netplan

lxc-stop -n ${container}
lxc-start -n ${container}

lxc-attach -n ${container} -- apt-get update
lxc-attach -n ${container} -- apt-get -y upgrade
lxc-attach -n ${container} -- apt-get -y install joe screen conky ifupdown kea-dhcp4-server iptables unbound


