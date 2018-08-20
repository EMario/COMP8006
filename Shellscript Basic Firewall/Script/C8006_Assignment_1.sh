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
output="OUTPUT"
input="INPUT"
forward="FORWARD"
default_port="0"
ssh_port="22"
dns_port="53"
dhcp_port1="67"
dhcp_port2="68"
http_port="80"
udp="udp"
tcp="tcp"
iptables -F
iptables -X
iptables -Z
# Sets the tables to drop every packet in default
iptables -P $input DROP
iptables -P $output DROP
iptables -P $forward DROP
#Create ip accounting chains
iptables -N ssh_traffic
iptables -N http_traffic
iptables -N other_traffic
iptables -A ssh_traffic -j ACCEPT
iptables -A http_traffic -j ACCEPT
iptables -A other_traffic -j ACCEPT
# Sets the policies to accept SSH connections
for var in $input $output
do
iptables -A $var -m $tcp -p $tcp --dport $ssh_port -j ssh_traffic
iptables -A $var -m $tcp -p $tcp --sport $ssh_port -j ssh_traffic
done
# Sets the policies to accept HTTP, DHCP and DNS connections
for var in $input $output
do
iptables -A $var -m $tcp -p $tcp --dport $http_port --sport 53 -j http_traffic
iptables -A $var -m $tcp -p $tcp --dport $http_port --sport 67:68 -j http_traffic
iptables -A $var -m $tcp -p $tcp --dport $http_port --sport 1024:65535 -j http_traffic
iptables -A $var -m $tcp -p $tcp --sport $http_port --dport 53 -j http_traffic
iptables -A $var -m $tcp -p $tcp --sport $http_port --dport 67:68 -j http_traffic
iptables -A $var -m $tcp -p $tcp --sport $http_port --dport 1024:65535 -j http_traffic
iptables -A $var -m $udp -p $udp --dport $dns_port -j other_traffic
iptables -A $var -m $udp -p $udp --sport $dns_port -j other_traffic
iptables -A $var -m $udp -p $udp --dport $dhcp_port1 -j other_traffic
iptables -A $var -m $udp -p $udp --sport $dhcp_port1 -j other_traffic
iptables -A $var -m $udp -p $udp --dport $dhcp_port2 -j other_traffic
iptables -A $var -m $udp -p $udp --sport $dhcp_port2 -j other_traffic
done
#Sets the policies to drop any packets incoming or outbound to port 0
for var1 in $input $output
do
for var2 in $tcp $udp
do
iptables -A $var1 -m $var2 -p $var2 --dport $default_port -j DROP
iptables -A $var1 -m $var2 -p $var2 --sport $default_port -j DROP
done
done
# Drops SYN Flags
iptables -A INPUT -m $tcp -p $tcp --tcp-flags SYN,RST,ACK SYN -j DROP #--tcp-flags ALL SYN 
iptables -A OUTPUT -m $tcp -p $tcp --tcp-flags SYN,RST,ACK SYN -j DROP
iptables -L
