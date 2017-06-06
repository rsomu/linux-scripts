# Purpose: To clone a Linux host that is hosted on Pure FlashArray SAN volume
#
# Usage: clonesys.sh
# Script reads one record at a time from hosts.txt file which has the following format:
# <hostname> <Public IP address> <Private IP address> <Hostname as in Pure Array> <Public MAC addr> <Private MAC addr>
#
# The script updates the network config & hostname on the source server with the details from hosts.txt for every server
# and takes Pure FlashRecover snapshot, instantiates the snapshot to a volume and attaches the volume to the target server.
#
# The functions pubip_config, prvip_config and snap_copy should be updated to meet your environment requirements
# like relevant network interface names, Pure FlashArray host name and volume name
#

function pubip_config {
  cat << EOF > /etc/sysconfig/network-scripts/ifcfg-enp6s0  # Update the filename to reflect the right interface
TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=yes
NAME=enp6s0    # Update to reflect the right interface
DEVICE=enp6s0  # Update to reflect the right interface
ONBOOT=yes
PEERDNS=no
IPADDR=$1
HWADDR=$2
PREFIX=24
GATEWAY=<your Gateway IP>
DNS1=<your DNS1>
DNS2=<your DNS2>
DOMAIN=<your domain>
EOF
}

function prvip_config {
  cat << EOF2 > /etc/sysconfig/network-scripts/ifcfg-enp7s0  # Update the filename to reflect the right interface
TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=no 
NAME=enp7s0    # Update to reflect the right interface
DEVICE=enp7s0  # Update to reflect the right interface
ONBOOT=yes
IPADDR=$1
HWADDR=$2
PREFIX=24
EOF2
}

function upd_host {
  hostname $1
  echo $1 > /etc/hostname
}

function snap_copy {
# ssh needs -n so it doesn't read from stdin which gets into the way with WHILE loop that reads from the file
# Update pureflasharray with the right FlashArray hostname
#
  ssh -n pureuser@pureflasharray purevol snap --suffix linux-gold-$1 <SAN boot volume name>
  ssh -n pureuser@pureflasharray purevol copy --overwrite <SAN boot volume name>.linux-gold-$1 $1-bootvol
  ssh -n pureuser@pureflasharray purehost connect --lun 1 --vol $1-bootvol $2
}

# Preserve the hostname and network interface config of the source system
ohost=$(hostname)
cp /etc/sysconfig/network-scripts/ifcfg-enp7s0 /etc/sysconfig/network-scripts/ifcfg-enp7s0.orig
cp /etc/sysconfig/network-scripts/ifcfg-enp6s0 /etc/sysconfig/network-scripts/ifcfg-enp6s0.orig

while read host pubip prvip purehname pubmac prvmac
do
  echo "Working on $host"
  prvip_config $prvip $prvmac
  pubip_config $pubip $pubmac
  upd_host $host
  sync
  snap_copy $host $purehname
  sleep 2
done < hosts.txt

# Revert back the hostname and network interface config back to the source system
upd_host $ohost
mv /etc/sysconfig/network-scripts/ifcfg-enp6s0.orig /etc/sysconfig/network-scripts/ifcfg-enp6s0
mv /etc/sysconfig/network-scripts/ifcfg-enp7s0.orig /etc/sysconfig/network-scripts/ifcfg-enp7s0