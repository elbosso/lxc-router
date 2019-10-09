# lxc-router

<!---
[![start with why](https://img.shields.io/badge/start%20with-why%3F-brightgreen.svg?style=flat)](http://www.ted.com/talks/simon_sinek_how_great_leaders_inspire_action)
--->
[![GitHub release](https://img.shields.io/github/release/elbosso/lxc-router/all.svg?maxAge=1)](https://GitHub.com/elbosso/lxc-router/releases/)
[![GitHub tag](https://img.shields.io/github/tag/elbosso/lxc-router.svg)](https://GitHub.com/elbosso/lxc-router/tags/)
[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![GitHub license](https://img.shields.io/github/license/elbosso/lxc-router.svg)](https://github.com/elbosso/lxc-router/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/elbosso/lxc-router.svg)](https://GitHub.com/elbosso/lxc-router/issues/)
[![GitHub issues-closed](https://img.shields.io/github/issues-closed/elbosso/lxc-router.svg)](https://GitHub.com/elbosso/lxc-router/issues?q=is%3Aissue+is%3Aclosed)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/elbosso/lxc-router/issues)
[![GitHub contributors](https://img.shields.io/github/contributors/elbosso/lxc-router.svg)](https://GitHub.com/elbosso/lxc-router/graphs/contributors/)
[![Github All Releases](https://img.shields.io/github/downloads/elbosso/lxc-router/total.svg)](https://github.com/elbosso/lxc-router)
[![Website elbosso.github.io](https://img.shields.io/website-up-down-green-red/https/elbosso.github.io.svg)](https://elbosso.github.io/)

This project holds scripts for setting up lightweight containers for various use cases. Kind of like docker scripts but without docker.

## Preconditions

This script has been extensively tested on the latest long term support version of Ubuntu - this being 18.04. When trying to use it on other distributions or flavours there may be incompatibilities or other problems, prohibiting productive use.

The server that is going to host the resulting appliances must have linux-bridges available. On Ubuntu and derivates this can be achieved by installing the package named bridge-utils by issuing for example `sudo apt install bridge-utils`. 

The server that is going to host the resulting appliances should also have IPv4-Forwarding enabled. This can be achieved either by issuing `echo 1 > /proc/sys/net/ipv4/ip_forward` or `sysctl -w net.ipv4.ip_forward=1` but this change will be gone after the next boot. To make this change persistent, edit _/etc/sysctl.conf_ and change the value of `net.ipv4.ip_forward = 1`. To read the current state of affairs, one can issue either `sysctl net.ipv4.ip_forward` or `cat /proc/sys/net/ipv4/ip_forward`.

As a router appliance needs to be connected to two bridges it is necessary to create them. This can be done by issuing `brctl addbr <name_of_bridge>`. This however is only good until after the next reboot. Another possibility - and one that is persistent and survives the next reboot - is to append the following snippet to _/etc/network/interfaces_  for each bridge needed:

```
auto <name_of_bridge>
iface <name_of_bridge> inet dhcp
  bridge_ports none
```

Of course, one has to get rid of *netplan* and install *ifupdown* before this can work.

The safest bet is to call `service networking restart` afterwards to activate the changes

## setup_router.sh

This script sets up a LXC container that can act as a router or gateway. It has several command line parameters. Their meaning is as follows:

```
./setup_router.sh <container> <extdev> <intdev> <intaddress> <intmask> <nameserver> <intdomain> [<staticip>] [<staticmask>]
```
<dl>
  <dt>container</dt><dd>The name of the container to be created</dd>
  <dt>extdev</dt><dd>The name of the device on the host the external network adapter should be connected to. This is the adapter the router is using to connect to the internet. We assume here that both adapters are <a href="https://linux.die.net/man/8/brctl">bridges</a>.</dd>
  <dt>intdev</dt><dd>The name of the device on the host the internal network adapter should be connected to. This is the adapter where the router is providing DNS service as well as DHCP service. We assume here that both adapters are <a href="https://linux.die.net/man/8/brctl">bridges</a>.</dd>
  <dt>intaddress</dt><dd>The IPv4 address for the routers internal network device (intdev).</dd>
  <dt>intmask</dt><dd>The netmask for the routers internal network device (intdev).</dd>
  <dt>nameserver</dt><dd>The parent nameserver - it is used when dnsmasq itself does not know about a particular name - the query is delegated then to the DNS server given here.</dd>
  <dt>intdomain</dt><dd>The domain for the hosts on the internal network device (intdev).</dd>
  <dt>staticip</dt><dd>If the external interface of the appliance should get
  a static ip - this is the place to specify it. If this parameter is not
  given, DHCP is assumed for the exernal interface.</dd>
  <dt>staticmask</dt><dd>This parameter is only evaluated if a ststic ip is
  specified for the external interface. In this case, this parameter
  specifies the netmask for the network the external interface is added to.
  If the parameter is not specified explicitly, 255.255.255.0 (/24) is
  assumed. </dd>
</dl>

The router is set up so that it works as out-of-the-box router and gateway for devices in the internal network. After setup, devices in this network (connected to the bridge intdev is also connected to) get a IPv4 address from the routers DHCP service as well as a gateway and a DNS server address and can connect to the internet.

The firewall rules are rather restrictive after setup - the clients can only access the internet and no one can access any clients.
The DHCP addresses given out by the DHCP server lie in the same network than does the routers internal interface (intaddress).

There is no installation of an SSH-server on this appliance - if it is
needed, it has to be installed separately.

Additionally, no password is set for the default user account named ubuntu.
If the user wants to use the console or SSH to login, some administrator has
to set a password for this account first (or create entirely new accounts of
course).
