#!/bin/bash
# Israel Torres
# 20170310
# ./get-netinfo.sh
# gets your netinfo and displays it, great to use for wrapping nmap
# or rolling reports that contain more information about your source
# version 1.1 (cleaned up, simple outputs)
# todo: variablize all, change "Network:" to "CIDR:"
# todo: add cli options -interface xxx (or) -ipcalc ip/netmask
# todo: output options, inline csv, or formatted as default (desc:\tval)
# todo: clean up source format
#
# requirements:
# ifconfig
# ipcalc 0.41 (tested version)
#
interface="$1"
######################################################################
if [[ -z "$interface" ]]
    then
        echo -en "usage:\tget-netinfo.sh interface (en0, en1, etc)\n"
        exit 1
fi
######################################################################
timestamp=$(date +%Y%m%d-%H%M%S)
NIC=$(ifconfig "$interface")
######################################################################
# 1. Mac Address, expected output xx:xx:xx:xx:xx
mAd=$(echo "$NIC" | grep -e 'ether' | tr -s ' ' | cut -d ' ' -f 2)
# 2. IPv4 Address, expectd output xxx.xxx.xxx.xxx
nIP=$(echo "$NIC" | grep -w 'inet' | tr -s ' ' | cut -d ' ' -f 2)
# 3. Netmask, expected output 0xyyyyyyyy
nmH=$(echo "$NIC" | grep -w 'netmask' | tr -s ' ' | cut -d ' ' -f 4)
# need to convert ifconfig version of netmask, expected output xxx.xxx.xxx.xxx
nmD=$(
    dot=0
    for x in $(
        echo "$nmH" \
        | cut -d 'x' -f 2 \
        | fold -2
        )
        do
            echo -en "$((16#$x))"
            dot=$((dot+1))
            if [[ "$dot" -lt "4" ]]
                then
                    echo -en "."
            fi
        done
    )
# end of nmD capture, expected output xxx.xxx.xxx.xxx
# 4. Broadcast, expected output xxx.xxx.xxx.xxx
bcD=$(echo "$NIC" | grep -w 'broadcast' | tr -s ' ' | cut -d ' ' -f 6)
# get more information from ipcalc, and format it for output
nfo=$(
    ipcalc  --nocolor --nobinary "$nIP"/"$nmD" \
    | grep -v -w -E 'Address:|Netmask:|=>|Hosts/Net:' \
    | sed '/^\s*$/d'
    ) # end of nfo capture, expected wildcard-broadcast IP
# get class info from ipcalc, and format it for output
cln=$(
    ipcalc  --nocolor --nobinary "$nIP"/"$nmD" \
    | grep -w 'Class' \
    | cut -d ',' -f 1,2 \
    | tr -s ' ' \
    | cut -d ' ' -f 3-10 \
    | sed '/^\s*$/d'
    ) # end of cln capture, expected output Class A, Private Internet
# get remote IP (this can be changed to any raw handler, abuse wil cause change, and API key)
iIP=$(curl -s --location israeltorres.org/ip.php)
# get orgname from whois if available
iWi=$(whois "$iIP"| grep -E 'NET-|OrgName')
######################################################################
# --- test case 01 begin ---
# expected input
# get-netinfo.sh en1
#
# expected output
#timestamp: 20170416-094118
#interface: en1
#MAC addy : 00:00:00:00:00:00
#IP addy  : 100.100.x.101
#Netmask  : 255.255.255.0
#Broadcast: 100.100.x.255
#Wildcard:  0.0.0.255
#Network:   100.100.x.0/24
#HostMin:   100.100.x.1
#HostMax:   100.100.x.254
#Broadcast: 100.100.x.255
#ClassifID: Class C, Private Internet
#Internet:  100.100.x.111
#Whois:
#ISP Communications Inc. NETBLK-...
#Provider Communications Inc. PRO-...
####################################################
# --- test case 01 end ---
#
#format all output and print it out to screen
echo -en "timestamp: $timestamp\n"
echo -en "interface: $interface\n"
echo -en "MAC addy : $mAd\n"
echo -en "IP addy  : $nIP\n"
echo -en "Netmask  : $nmD\n"
echo -en "Broadcast: $bcD\n"
echo -en "$nfo\n"
echo -en "ClassifID: $cln\n"
echo -en "Internet:  $iIP\n"
echo -en "Whois:\n$iWi\n"
#
#EOF

