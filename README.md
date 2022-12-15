# AsusMerlin-WireGuard-Failover

## Script to perform failover for wireguard client VPN. This script is a simple attempt to make sure the wireguard VPN client is always connected to a server by performing frequently monitoring latest handshake time checks.

Usage:

1. Login to the router admin colsole (WebUI - ```http://router.asus.com``` (or) whatever gateway address you have set for you router ```http://192.168.1.1``` or ```http://10.0.0.1``` ....) and make sure the JFFS custom scripts and SSH options are enabled under Administration&rarr;System
2. SSH into router and place the shell script ```wg_vpn_failover.sh``` under ```/jffs/scripts/```
3. Create a new folder called ```wg_vpn_config_files``` under ```/jffs/configs/``` and drop your wireguard client config files that you have downloaded from your VPN provider
4. Under ```/jffs/scripts/``` create a new file called ```wg_vpn_failover_config``` and add enter the configurations that you want to failover to in the order you prefer, example:
```
1       PIA-Orlando.conf     PIA-Orlando
2       Nord-Newyork.conf    Nord-Newyork
3       PIA-Austin.conf PIA-Austin
4       PIA-Denver.conf     PIA-Denver
5       PIA-Boston.conf      PIA-Boston
```
5. Under /jffs/scripts/ edit the services-start file (if the file is not available create one) and enter the below lines
``` sh
#!/bin/sh

sh /jffs/scripts/wg_vpn_failover.sh
```
6. Restart the router
