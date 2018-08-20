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
#Reset the table values to accept everything
iptables -F
iptables -X
iptables -Z
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -L
