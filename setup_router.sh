#!/bin/bash
script=${0}
script_dir=`dirname $script`

container=${1}
extdev=${2}
intdev=${3}
intaddress=${4}
intmask=${5}

echo "operating from within ${script_dir}"

echo "building container ${container}..."

lxc-create -t download -n ${container} -- -d ubuntu -r bionic  -a amd64

sed -i "s/lxc.net.0.link =.*/lxc.net.0.link = ${extdev}/g" /var/lib/lxc/${container}/config
echo "lxc.net.1.type = veth" >> /var/lib/lxc/${container}/config 
echo "lxc.net.1.link = ${intdev}" >> /var/lib/lxc/${container}/config
echo "lxc.net.1.flags = up" >> /var/lib/lxc/${container}/config

lxc-start -n ${container}

lxc-attach -n ${container} -- apt-get -y remove netplan

lxcpath=`lxc-config lxc.lxcpath`
rootfs=`lxc-info -n ${container} -c lxc.rootfs.path|rev|cut -d " " -f 1|cut -d ":" -f 1|rev`
containerpath=`echo ${lxcpath}"/"${container}`

cp ${script_dir}/interfaces ${script_dir}/interfaces.work
sed -i "s/intmask/${intmask}/g" ${script_dir}/interfaces.work
sed -i "s/intaddress/${intaddress}/g" ${script_dir}/interfaces.work

#lxc file push ${script_dir}/interfaces.work ${container}/etc/network/interfaces
cp ${script_dir}/interfaces.work ${rootfs}/etc/network/interfaces


lxc-stop -n ${container}
lxc-start -n ${container}

lxc-attach -n ${container} -- apt-get update
lxc-attach -n ${container} -- apt-get -y upgrade
lxc-attach -n ${container} -- apt-get -y install joe screen conky ifupdown kea-dhcp4-server iptables unbound

intsubnet=`echo ${intaddress} | cut -d"." -f1-3`

cp ${script_dir}/kea-dhcp4.conf ${script_dir}/kea-dhcp4.conf.work
sed -i "s/intsubnet/${intsubnet}/g" ${script_dir}/kea-dhcp4.conf.work

cp ${script_dir}/kea-dhcp4.conf.work ${rootfs}/etc/kea/kea-dhcp4.conf

lxc-attach -n ${container} -- systemctl enable kea-dhcp4-server

lxc-attach -n ${container} -- service kea-dhcp4-server stop
lxc-attach -n ${container} -- service kea-dhcp4-server start

cp ${script_dir}/router.conf ${script_dir}/router.conf.work
sed -i "s/intsubnet/${intsubnet}/g" ${script_dir}/router.conf.work

cp ${script_dir}/router.conf.work ${rootfs}/etc/unbound/unbound.conf.d/router.conf

lxc-attach -n ${container} -- service unbound stop
lxc-attach -n ${container} -- service unbound start

lxc-attach -n ${container} -- iptables -A FORWARD -o eth0 -i eth1 -s ${intsubnet}.0/24 -m conntrack --ctstate NEW -j ACCEPT
lxc-attach -n ${container} -- iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
lxc-attach -n ${container} -- iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#lxc-attach -n ${container} -- 

lxc-attach -n ${container} -- bash -c "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections"
lxc-attach -n ${container} -- bash -c "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections"

lxc-attach -n ${container} -- apt-get install -y iptables-persistent
