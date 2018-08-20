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
PNG="hping3"
MAP="nmap"

#Address to test
TESTADDR="192.168.0.3"
SPOOF="192.168.10.5"

#Test Values
ERRTCP="1022,28,23"
ERRUDP="11"
ERRICMP="1"
TESTTCP="80,22,443"
TESTUDP="53"
TESTICMP="3,8"

echo "INITIALIZING ERROR TESTS"
echo "THE FOLLOWING PORTS ARE NOT ALLOWED:"
echo "TCP (TESTS should demonstrate 0% packet success):"
for i in $(echo $ERRTCP | sed "s/,/ /g")
do
	$PNG $TESTADDR -p $i -c 3
done
echo "UDP:" >> $filename
	$MAP -v -sU -p $ERRUDP $TESTADDR
echo "ICMP (TESTS should demonstrate 0% packet success):"
	for i in $(echo $ERRICMP | sed "s/,/ /g")
do
	$PNG $TESTADDR -p $i -c 3
done
echo "INITIALIZING SUCCESS TESTS"
echo "THE FOLLOWING PORTS ARE ALLOWED:"
echo "TCP (TESTS should demonstrate 100% packet success):"
for i in $(echo $TESTTCP | sed "s/,/ /g")
do
	$PNG $TESTADDR -p $i -c 3
done
echo "UDP (TESTS should demonstrate open or close ports):"
$MAP -v -sU -p $TESTUDP $TESTADDR
echo "ICMP (TESTS should demonstrate 100% packet success):"
for i in $(echo $TESTICMP | sed "s/,/ /g")
do
	$PNG $TESTADDR -p $i -c 3
done
echo "Spoofing Adress (TESTS should demonstrate 100% packet failure):"
$PNG $TESTADDR -a $SPOOF -c 3
echo "SYN FIN packets (TESTS should demonstrate 100% packet failure):"
$PNG $TESTADDR -S -F -c 3
echo "ibound SYN packets to high ports (TESTS should demonstrate 100% packet failure):"
$PNG $TESTADDR -S -p 40000 -c 3
echo "Finished..."
