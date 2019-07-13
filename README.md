# lxc-router

This project holds scripts for setting up lightweight containers for various use cases. Kind of like docker scripts but without docker.

## setup_router.sh

This script sets up a LXC container that can act as a router or gateway. It has several command line parameters. Their meaning is as follows:

```
./setup_router.sh <container> <extdev> <intdev> <intaddress> <intmask>
```
<dl>
  <dt>container</dt><dd>The name of the container to be created</dd>
  <dt>extdev</dt><dd>The name of the device on the host the external network adapter should be connected to. This is the adapter the router is using to connect to the internet. We assume here that both adapters are [bridges](https://linux.die.net/man/8/brctl).</dd>
  <dt>intdev</dt><dd>The name of the device on the host the internal network adapter should be connected to. This is the adapter where the router is providing DNS service as well as DHCP service. We assume here that both adapters are [bridges](https://linux.die.net/man/8/brctl).</dd>
  <dt>intaddress</dt><dd>The IPv4 address for the routers internal network device (intdev).</dd>
  <dt>intmask</dt><dd>The netmask for the routers internal network device (intdev).</dd>
</dl>

The router is set up so that it works as out-of-the-box router and gateway for devices in the internal network. After setup, devices in this network (connected to the bridge intdev is also connected to) get a IPv4 address from the routers DHCP service as well as a gateway and a DNS server address and can connect to the internet.

The firewall rules are rather restrictive after setup - the clients can only access the internet and no one can access any clients.
The DHCP addresses given out by the DHCP server lie in the same network than does the routers internal interface (intaddress).


