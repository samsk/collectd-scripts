#!/bin/bash
###
# ABOUT  : collectd monitoring script for megaraid (using MegaCli)
# AUTHOR : Samuel B. <samuel_._behan_(at)_dob_._sk> (c) 2012
# LICENSE: GNU GPL v3
#          
# This script monitors physical drives of an LSi MegaRaid raid card.
# Generates output suitable for Exec plugin of collectd.
# 
# Requirements:
#   MegaCli binary:
#       /usr/local/sbin/MegaCli
#   sudo entry for binary (ie. for sys account):
#       sys   ALL = (root) NOPASSWD: /usr/local/sbin/MegaCli
#
# Parameters:
#   <adapter1>:<alias1> [ <adapter2>:<alias2> ... ]
#
# Typical usage:
#   /etc/collect/megamon.sh "0:sda" "1:sdb"
#
#   Will monitor adapter megaraid 0 and alias it as sda drive. Physical drives
#   of this adapter will be named like <alias><PhysicalDrive ID>.
#
# Typical output:
#   PUTVAL <host>/megamon-sda5/gauge-media_error_count interval=300 N:0
#   PUTVAL <host>/megamon-sda5/gauge-other_error_count interval=300 N:0
#   PUTVAL <host>/megamon-sda5/gauge-predictive_fail_count interval=300 N:0
#   PUTVAL <host>/megamon-sda5/gauge-state interval=300 N:1
#   PUTVAL <host>/megamon-sda6/gauge-media_error_count interval=300 N:11
#   PUTVAL <host>/megamon-sda6/gauge-other_error_count interval=300 N:0
#   PUTVAL <host>/megamon-sda6/gauge-predictive_fail_count interval=300 N:0
# ...
#
###

if [ -z "$*" ];
then	echo "usage: $0 <id:name> <id:name>..." >&2;
	exit 1;
fi;

#HOST=localhost
HOST=`hostname -f`
INTERVAL=300
while true
do
	for disk in "$@";
	do  dsk=${disk%:*};
	    name=${disk#*:};

	    vars="media_error_count other_error_count predictive_fail_count state";
	    sudo /usr/local/sbin/MegaCli -LDPDInfo -a$dsk -NoLog | awk '
	    		/^Device Id:/ || /^Media Error Count:/ || /^Other Error Count:/ || /^Predictive Failure Count/ { printf $NF " " };
	    		/^Firmware state: / { if ($3 ~ /^Online/) { printf "1\n" } else { printf "0\n" } }' | (

		while read id $vars;
		do
			for var in $vars;
			do
				echo "PUTVAL $HOST/megamon-$name$id/gauge-$var interval=$INTERVAL N:$(eval echo \$$var)";
			done;
		done;
	    )
	done;

	sleep $INTERVAL || true;
done
