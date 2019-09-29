#!/bin/bash
# shellcheck disable=SC2181
#script="$0"
script_dir=$(dirname $"script")

#config variables from command line arguments
container="$1"
extdev="$2"
intdev="$3"
intaddress="$4"
intmask="$5"
nameserver="$6"
intdomain="$7"
staticip="${8:-dhcp}"
staticmask="${9:-255.255.255.0}"

echo "operating from within $script_dir"

ip link show "$intdev" > /dev/null 2>&1 
if [ $? -ne 0 ]
then
        echo "$intdev does not exist - exiting..."
        exit 1
fi
ip link show "$extdev" > /dev/null 2>&1 
if [ $? -ne 0 ]
then
        echo "$extdev does not exist - exiting..."
        exit 2
fi

lxc-info -n "$container"
if [ $? -eq 0 ]
then
	echo "container already there - aborting!"
	exit 1
fi
echo "building container $container..."

#lxc-create for the container - at this moment, we always build a bionic beaver ubuntu container
lxc-create -t download -n "$container" -- -d ubuntu -r bionic  -a amd64

lxc-info -n "$container"
if [ $? -ne 0 ]
then
	echo "container creation failed - aborting!"
	exit 2
fi
#changing the config of the container so it has the interfaces named
#at startup properly assigned
sed -i "s/lxc.net.0.link =.*/lxc.net.0.link = $extdev/g" /var/lib/lxc/"$container"/config
{ echo "lxc.net.1.type = veth" ;echo "lxc.net.1.link = $intdev" ;echo "lxc.net.1.flags = up"; } >> /var/lib/lxc/"$container"/config

#starting the container
lxc-start -n "$container"
lxc-wait -n "$container" -s RUNNING

#Because we do not use or require LXD at this point,
#we can not use lxc push file
#so we have to cp files and to be able to do so - we
#need to know where the root file system of the container is located
#lxcpath=$(lxc-config lxc.lxcpath)
rootfs=$(lxc-info -n "$container" -c lxc.rootfs.path|rev|cut -d " " -f 1|cut -d ":" -f 1|rev)
#containerpath="$lxcpath"/"$container"

#Now we customize the network interface configuration and
#copy it to the right place inside the containers file system
if [ "$staticip" == "dhcp" ]; 
then
  cp "$script_dir"/interfaces_external_dhcp "$script_dir"/interfaces.work
else
  cp "$script_dir"/interfaces_external_static "$script_dir"/interfaces.work
  sed -i "s/staticmask/$staticmask/g" "$script_dir"/interfaces.work
  sed -i "s/staticaddress/$staticip/g" "$script_dir"/interfaces.work
  sed -i "s/nameserverip/$nameserver/g" "$script_dir"/interfaces.work
fi
sed -i "s/intmask/$intmask/g" "$script_dir"/interfaces.work
sed -i "s/intaddress/$intaddress/g" "$script_dir"/interfaces.work

#lxc file push "$script_dir"/interfaces.work "$container"/etc/network/interfaces
cp "$script_dir"/interfaces.work "$rootfs"/etc/network/interfaces

#we restart the container to have the interfaces correctly configured
#at our disposition
lxc-stop -n "$container"
lxc-wait -n "$container" -s STOPPED
lxc-start -n "$container"
lxc-wait -n "$container" -s RUNNING

sleep 5

#Now we install ll needed packages
#(or some the author deems necessary...)
lxc-attach -n "$container" -- apt-get update
lxc-attach -n "$container" -- apt-get -y upgrade
lxc-attach -n "$container" -- apt-get -y install joe screen conky ifupdown dnsmasq iptables

intsubnet=$(echo "$intaddress" | cut -d"." -f1-3)

#Now we customize the dnsmasq configuration and
#copy it to the right place inside the containers file system
cp "$script_dir"/dnsmasq.conf "$script_dir"/dnsmasq.conf.work
sed -i "s/intsubnet/$intsubnet/g" "$script_dir"/dnsmasq.conf.work
sed -i "s%#local=/localnet/%local=/$intdomain/%g" "$script_dir"/dnsmasq.conf.work
sed -i "s/domain=intdomain.lab/domain=$intdomain/g" "$script_dir"/dnsmasq.conf.work
cp "$script_dir"/dnsmasq.conf.work "$rootfs"/etc/dnsmasq.conf

#we install our own version of /etc/resolv.conf...
lxc-attach -n "$container" -- rm /etc/resolv.conf
lxc-attach -n "$container" -- /bin/bash -c "echo 'nameserver 127.0.0.1' >/etc/resolv.conf"
lxc-attach -n "$container" -- /bin/bash -c "echo 'nameserver $nameserver' >>/etc/resolv.conf"

#we want to use dnsmasq as DNS server but systemd hogs the standard DNS port - 
#therefore, it has to go
lxc-attach -n "$container" -- /bin/bash -c "mkdir -p /run/dbus"
lxc-attach -n "$container" -- /bin/bash -c "dbus-daemon --system"
lxc-attach -n "$container" -- /bin/bash -c "systemctl stop systemd-resolved.service"
lxc-attach -n "$container" -- /bin/bash -c "systemctl disable systemd-resolved.service"

lxc-attach -n "$container" -- service dnsmasq stop
lxc-attach -n "$container" -- service dnsmasq start

#now it is time for configuring the firewall...
lxc-attach -n "$container" -- iptables -A FORWARD -o eth0 -i eth1 -s "$intsubnet".0/24 -m conntrack --ctstate NEW -j ACCEPT
lxc-attach -n "$container" -- iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
lxc-attach -n "$container" -- iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#lxc-attach -n "$container" -- 

#make the firewall rules persistent...
lxc-attach -n "$container" -- /bin/bash -c "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections"
lxc-attach -n "$container" -- /bin/bash -c "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections"

lxc-attach -n "$container" -- apt-get install -y iptables-persistent
lxc-attach -n "$container" -- apt-get -y autoremove
lxc-attach -n "$container" -- apt-get clean

lxc-stop -n "$container"
lxc-wait -n "$container" -s STOPPED

lxc-start -n "$container"
lxc-wait -n "$container" -s RUNNING

#netplan: arghhh! We want ifupdown and so we need to get rid of 
#this junk!
lxc-attach -n "$container" -- apt-get -y remove netplan
lxc-attach -n "$container" -- rm -rf /etc/netplan

lxc-stop -n "$container"
lxc-wait -n "$container" -s STOPPED

lxc-start -n "$container"
lxc-wait -n "$container" -s RUNNING

ip link show "$intdev" | grep "state UP" > /dev/null
if [ $? -ne 0 ]
then
	echo "$intdev is not up (yet) - is this on purpose?"
fi
ip link show "$extdev" | grep "state UP" > /dev/null
if [ $? -ne 0 ]
then
	echo "$extdev is not up (yet) - is this on purpose?"
fi
