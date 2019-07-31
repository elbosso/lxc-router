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

## setup_router.sh

This script sets up a LXC container that can act as a router or gateway. It has several command line parameters. Their meaning is as follows:

```
./setup_router.sh <container> <extdev> <intdev> <intaddress> <intmask> <nameserver> <intdomain>
```
<dl>
  <dt>container</dt><dd>The name of the container to be created</dd>
  <dt>extdev</dt><dd>The name of the device on the host the external network adapter should be connected to. This is the adapter the router is using to connect to the internet. We assume here that both adapters are <a href="https://linux.die.net/man/8/brctl">bridges</a>.</dd>
  <dt>intdev</dt><dd>The name of the device on the host the internal network adapter should be connected to. This is the adapter where the router is providing DNS service as well as DHCP service. We assume here that both adapters are <a href="https://linux.die.net/man/8/brctl">bridges</a>.</dd>
  <dt>intaddress</dt><dd>The IPv4 address for the routers internal network device (intdev).</dd>
  <dt>intmask</dt><dd>The netmask for the routers internal network device (intdev).</dd>
  <dt>nameserver</dt><dd>The parent nameserver - it is used when dnsmasq itself does not know about a particular name - the query is delegated then to the DNS server given here.</dd>
  <dt>intdomain</dt><dd>The domain for the hosts on the internal network device (intdev).</dd>
</dl>

The router is set up so that it works as out-of-the-box router and gateway for devices in the internal network. After setup, devices in this network (connected to the bridge intdev is also connected to) get a IPv4 address from the routers DHCP service as well as a gateway and a DNS server address and can connect to the internet.

The firewall rules are rather restrictive after setup - the clients can only access the internet and no one can access any clients.
The DHCP addresses given out by the DHCP server lie in the same network than does the routers internal interface (intaddress).
