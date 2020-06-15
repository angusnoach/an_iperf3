#!/bin/bash

# script: run.sh; version: 2006.5
# run script for iperf3 server mode
# copyright reserved by angusnoach

##################
# initialization #
##################

TRUE=0
FALSE=1
LOGFILE="/data/iperf3.log"
MAXCOUNT=999


##################
# main functions #
##################

#------------------------------------------------------------------------------
# $1 = loop value
function writeLog {
  if [ $1 -eq 0 ]; then
    echo "===========================================================" > $LOGFILE
    echo "Report for iperf speed test" >> $LOGFILE
  else
    echo "===========================================================" >> $LOGFILE
    echo "Report #$1 ended on [$(date +%Y/%m/%d-%H:%M:%S)]" >> $LOGFILE
  fi
}

##################
# main procedure #
##################

COUNT=0

while : ; do
  writeLog $COUNT
  iperf3 -s -1 >> $LOGFILE
  (( COUNT++ ))
  if [ $COUNT -gt $MAXCOUNT ]; then
    COUNT=0
  fi
  sleep 1  # able to be interrupted by hand
done
