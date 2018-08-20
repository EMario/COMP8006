###############################################
##
##	COMP 8006	Reset file
##
##	Author:	Mario Enriquez
##
##	Id:		A00909441
##
##	Date:	January 28, 2016
##
###############################################


########################################################
## User Configuration
########################################################
#Name and Location of the utility to use for the firewall
FRWLL="iptables"
DIR="/sbin"
PNG="hping3"
MAP="nmap"

#Internal Network, Adress Space and Device
INET="192.168.10.0/24"
IADDR="192.168.10.1/24"
FWADDR="192.168.10.2/24"
ADDR1="192.168.10.1" #Internal Host Address
ADDR2="192.168.10.2" #Prerouting Address
IDEV="enp3s2"

#External Address Space and Device
EADDR="0.0.0.0/0"
EDEV="eno1"
ENET="192.168.0.0"
GADDR="192.168.0.1"

#TCP Services Allowed
TCPINP="ssh,ftp,ftp-data,www,https,domain"
TCPOUT="ssh,ftp,ftp-data,www,https"

#UDP Services Allowed
UDPINP="domain,www,ssh,https"
UDPOUT="domain,www,ssh,https"

#ICMP Services Allowed
ICMPREC="0,3,8"
ICMPSENT="0,3,8"

#Test Values
TADDR="192.168.0.3"
ERRTCP="1022,28,23"
ERRUDP="11"
ERRICMP="1"
TESTTCP="80,22,443"
TESTUDP="53"
TESTICMP="3,8"

########################################################
## Implementation
########################################################

#Sets the value for the menu
selection=-1;

#While cycle to set the firewall or the Addresses
while [ $selection -ne 5 ]
do
	echo "Please Write what you want to do:"
	echo "1) Create Firewall"
	echo "2) Set the configuration for the Firewall machine" 
	echo "3) Set the configuration for the Host Machine"
	echo "4) Reset the Firewall"
	echo "5) Exit"
	read selection
	if [ $selection -eq 1 ]
	then
		#Reset Netfilter
		$FRWLL -F
		$FRWLL -X
		$FRWLL -Z
		$FRWLL -t nat -F
		$FRWLL -t nat -X
		$FRWLL -t nat -Z
		$FRWLL -t nat -F
		$FRWLL -t nat -X
		$FRWLL -t nat -Z

		#Reset IP route

		#Create Accounting Chains
		iptables -N tcp_in
		iptables -N tcp_out
		iptables -N udp_in
		iptables -N udp_out
		iptables -N icmp_in
		iptables -N icmp_out
		iptables -N fragm
		iptables -A tcp_in -j ACCEPT
		iptables -A tcp_out -j ACCEPT
		iptables -A udp_in -j ACCEPT
		iptables -A udp_out -j ACCEPT
		iptables -A icmp_in -j ACCEPT
		iptables -A icmp_out -j ACCEPT
		iptables -A fragm -j ACCEPT

		#Set the initial default policies
		#All packets that fall through to the default rule will be dropped
		$FRWLL --policy INPUT DROP
		$FRWLL --policy OUTPUT DROP
		$FRWLL --policy FORWARD DROP
		$FRWLL -t nat --policy PREROUTING ACCEPT
		$FRWLL -t nat --policy OUTPUT ACCEPT
		$FRWLL -t nat --policy POSTROUTING ACCEPT
		$FRWLL -t mangle --policy PREROUTING ACCEPT
		$FRWLL -t mangle --policy OUTPUT ACCEPT

		#Accept DHCP to avoid getting errors
		$FRWLL -A INPUT -p tcp -m tcp --dport 67:68 -j ACCEPT
		$FRWLL -A OUTPUT -p tcp -m tcp --dport 67:68 -j ACCEPT
		$FRWLL -A INPUT -p tcp -m tcp --sport 67:68 -j ACCEPT
		$FRWLL -A OUTPUT -p tcp -m tcp --sport 67:68 -j ACCEPT

		#Inbound/Outbound TCP packets on allowed ports
		$FRWLL -A FORWARD -i $IDEV -o $EDEV -p tcp -m multiport --dport $TCPOUT \
		-j tcp_out -m state --state NEW,ESTABLISHED
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p tcp -m multiport --dport $TCPINP \
		-j tcp_in -m state --state NEW,ESTABLISHED
		$FRWLL -A FORWARD -i $IDEV -o $EDEV -p tcp -m multiport --sport $TCPOUT \
		-j tcp_out -m state --state NEW,ESTABLISHED
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p tcp -m multiport --sport $TCPINP \
		-j tcp_in -m state --state NEW,ESTABLISHED

		#Inbound/Outbound UDP packets on allowed ports
		$FRWLL -A FORWARD -p udp -m multiport --dport $UDPOUT \
		-j udp_out -m state --state NEW,ESTABLISHED
		#$FRWLL -A FORWARD -i $EDEV -o $IDEV -p udp -m multiport --dport $UDPINP \
		#-j udp_in -m state --state NEW,ESTABLISHED
		#$FRWLL -A FORWARD -i $IDEV -o $EDEV -p udp -m multiport --sport $UDPOUT \
		#-j udp_out -m state --state NEW,ESTABLISHED
		$FRWLL -A FORWARD -i -p udp -m multiport --sport $UDPINP \
		-j udp_in -m state --state NEW,ESTABLISHED

		#Inbound/Outbound ICMP packets based on type numbers
		for i in $(echo $ICMPREC | sed "s/,/ /g")
		do
		$FRWLL -A FORWARD -i $IDEV -o $EDEV -p icmp --icmp-type $i \
		-j icmp_out -m state --state NEW,ESTABLISHED
		done
		for i in $(echo $ICMPSENT | sed "s/,/ /g")
		do
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p icmp --icmp-type $i \
		-j icmp_in -m state --state NEW,ESTABLISHED
		done

		#Drop all TCP packets with the SYN and FIN bit set
		$FRWLL -A FORWARD -i $IDEV -o $EDEV -p tcp --tcp-flags FIN SYN -j DROP
		$FRWLL -A FORWARD -i $IDEV -o $EDEV -p tcp --tcp-flags SYN FIN -j DROP
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p tcp --tcp-flags FIN SYN -j DROP
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p tcp --tcp-flags SYN FIN -j DROP
		#Do not allow Telnet packets at all
		$FRWLL -A FORWARD -p tcp -m tcp --dport 23 -j DROP

		#Accept fragments
		$FRWLL -A FORWARD -i $EDEV -f -j fragm

		#Do  not  accept  any  packets  with  a  source  address  from  the  outside  matching  your internal network
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -s $INET -j DROP

		#Drop all packets destined for the firewall host from the outside
		$FRWLL -A INPUT -i $EDEV -j DROP 

		#Block all external traffic directed to ports 32768–32775, 137–139, TCP ports 111 and 515
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p tcp -m multiport --dport 32768:32775,137:139,111,515 \
		-j DROP 
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p udp -m multiport --dport 32768:32775,137:139 \
		-j DROP

		#ou must ensure the you reject those connections that are coming the “wrong” way 
		$FRWLL -A FORWARD -i $EDEV -o $IDEV -p tcp -m multiport --dport 1024:65535 -j DROP
		$FRWLL -A FORWARD -i $IDEV -o $EDEV -p udp -m multiport --dport 1024:65535 -j DROP

		#DNAT MASQUERADING AND PREROUTING
		echo "1" > /proc/sys/net/ipv4/ip_forward
		$FRWLL -t nat -A POSTROUTING -o $EDEV -j MASQUERADE
		$FRWLL -t nat -A PREROUTING -i $EDEV -j DNAT --to $ADDR2 

		#For FTP and SSH services, set control connections to "Minimum Delay" and FTP data to "Maximum Throughput"
		$FRWLL -A OUTPUT -t mangle -p tcp --dport ssh -j TOS --set-tos Minimize-Delay 
		$FRWLL -A OUTPUT -t mangle -p tcp --dport ftp -j TOS --set-tos Minimize-Delay 
		$FRWLL -A OUTPUT -t mangle -p tcp --dport ftp-data -j TOS \
		--set-tos Maximize-Throughput

		$FRWLL -A PREROUTING -t mangle -p tcp --sport ssh -j TOS --set-tos Minimize-Delay 
		$FRWLL -A PREROUTING -t mangle -p tcp --sport ftp -j TOS --set-tos Minimize-Delay 
		$FRWLL -A PREROUTING -t mangle -p tcp --sport ftp-data -j TOS \
		--set-tos Maximize-Throughput

		echo "Firewall created"
	fi
	if [ $selection -eq 2 ]
	then
		ip addr add $IADDR dev $IDEV
		ip link set $IDEV up
		ip route add $ENET via $GADDR dev $EDEV
		ip route add $ENET via $ADDR1 dev $IDEV	
		echo "Machine ready for Firewall implementation"
	fi
	if [ $selection -eq 3 ]
	then
		ip link set $EDEV down
		ip addr add $FWADDR dev $IDEV
		echo "1" > /proc/sys/net/ipv4/ip_forward
		ip link set $IDEV up
		ip route add default via $ADDR1
		echo "Machine ready as a Host"
	fi
	if [ $selection -eq 4 ]
	then
		$FRWLL -F
		$FRWLL -X
		$FRWLL -Z
		$FRWLL -P INPUT ACCEPT
		$FRWLL -P OUTPUT ACCEPT
		$FRWLL -P FORWARD ACCEPT
		$FRWLL -t nat --policy PREROUTING ACCEPT
		$FRWLL -t nat --policy OUTPUT ACCEPT
		$FRWLL -t nat --policy POSTROUTING ACCEPT
		$FRWLL -t mangle --policy PREROUTING ACCEPT
		$FRWLL -t mangle --policy OUTPUT ACCEPT
		$FRWLL -t nat --policy PREROUTING ACCEPT
		$FRWLL -t nat --policy OUTPUT ACCEPT
		$FRWLL -t nat --policy POSTROUTING ACCEPT
		$FRWLL -t mangle --policy PREROUTING ACCEPT
		$FRWLL -t mangle --policy OUTPUT ACCEPT
		echo "Tables Resetted"
	fi
done
