#!/bin/sh
########################################################
##
##	Author: Mario Enriquez
##
##	ID: 	A00909441
##
##	COMP 8006
##
########################################################

########################################################################
##  User Input
########################################################################

IP_TABL="iptables"
CONF_PATH="/root/Documents/C8006_Assignment_3/config"

########################################################################
##  Code
########################################################################

LOG_PATH=""
BLOCKED_IPS=""
PORT=""
JAVACLASS_PATH=""
JAVAFILE_NAME=""

results=$(grep "LOG_PATH" $CONF_PATH)

declare -i aux=0
i=""
for i in $results
do
aux=($aux+1)
if [ $aux = "3" ]
then
LOG_PATH=$i
fi
done

results=$(grep "PORT_" $CONF_PATH)

declare -i aux=0
i=""
for i in $results
do
aux=($aux+1)
if [ $aux = "3" ]
then
PORT_=$i
fi
done

results=$(grep "JAVACLASS_PATH" $CONF_PATH)

declare -i aux=0
i=""
for i in $results
do
aux=($aux+1)
if [ $aux = "3" ]
then
JAVACLASS_PATH=$i
fi
done

results=$(grep "JAVAFILE_NAME" $CONF_PATH)

declare -i aux=0
i=""
for i in $results
do
aux=($aux+1)
if [ $aux = "3" ]
then
JAVAFILE_NAME=$i
fi
done

java -cp $JAVACLASS_PATH $JAVAFILE_NAME $CONF_PATH

results=$(grep "Yes" $LOG_PATH)
aux=0
i=""
for i in $results
do
aux=($aux+1)
if [ $aux = "1" ]
then
BLOCKED_IPS+="$i "
fi
if [ $aux = "7" ]
then
aux=0
fi
done

$IP_TABL -F
$IP_TABL -X
$IP_TABL -Z

for i in $BLOCKED_IPS
do
$IP_TABL -A INPUT -s $i -p tcp --dport $PORT_ -j DROP
done
