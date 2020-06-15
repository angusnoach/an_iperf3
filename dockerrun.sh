#!/bin/bash

# script: dockerrun; version: 2006.6
# docker run for iperf3
# copyright reserved by angusnoach

##################
# initialization #
##################

TRUE=0
FALSE=1

CONTAINER="an_iperf3"
DC=$(pwd)
DD="$DC/data"

DEFAULT=
CTN_NAME="$(basename $(pwd))"
H_PORT=5201 # host port
C_PORT=5201 # container port

NET=

LOGDIR="/var/log/docker"
LOGFILE="$LOGDIR/$CONTAINER.log"
VER=$DD/version.txt


############
# function #
############

#------------------------------------------------------------------------------
function get_params {
  echo "[--] Managing parameters..." | tee -a $LOGFILE
  if [ $# -eq 0 ]; then
    get_help
  fi
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -n|--name)
        CTN_NAME=$2
        if [ "$2" == "" ]; then
          shift # past argument
        else
          shift # past argument
          shift # past value
        fi
      ;;
      -d)
        DEFAULT=Y
        if [ "$2" == "" ]; then
          shift # past argument
        else
          shift # past argument
          shift # past value
        fi
      ;;
      -p|--port)
        H_PORT=$2
        if [ "$2" == "" ]; then
          shift # past argument
        else
          shift # past argument
          shift # past value
        fi
      ;;
      -w|--network)
        NET=$2
        if [ "$2" == "" ]; then
          shift # past argument
        else
          shift # past argument
          shift # past value
        fi
      ;;
      *)    # unknown option
        get_help
      ;;
    esac
  done
}

#------------------------------------------------------------------------------
function chk_params {
  return
}

#------------------------------------------------------------------------------
function chk_image {
  CHK=$(docker images|grep -cw $1)
  if [ $CHK -gt 0 ]; then
    return $TRUE
  else
    return $FALSE
  fi
}

#------------------------------------------------------------------------------
function chk_container {
  CHK=$(docker container ls -a|grep -cw $1)
  if [ $CHK -gt 0 ]; then
    return $TRUE
  else
    return $FALSE
  fi
}

#------------------------------------------------------------------------------
function chk_network {
  local chk
  if [ ! "$1" == "" ]; then
    echo "[>>] Creating docker network: $1 if necessary..." | tee -a $LOGFILE
    chk=$(docker network ls|grep -cw $1)
    if [ $chk -eq 0 ]; then
      docker network create $1
    fi
  fi
}

#------------------------------------------------------------------------------
function chk_status {
  CHK=$(docker container ls|grep -cw "$1")
  if [ $CHK -gt 0 ]; then
    return $TRUE
  else
    return $FALSE
  fi
}

#------------------------------------------------------------------------------
function get_help {
  echo ""
  echo "[??] Docker Container for $CONTAINER:-"
  echo "[??] dockerrun.sh [-d] [-n|--name] {CTN_NAME} [-p|--port] {PORT} [-w|--network] {NETWORK}"

  echo "[??] where:"
  echo "[??] -d = create container with default settings"
  echo "[??] -p = port (default: $H_PORT)"
  echo "[??] -n = container name (default: current folder name)"
  echo "[??] -w = network name (default: system assigned)"
  echo "[??]"
  echo "[??] example:"
  echo "[??]   ./dockerrun.sh -d"
  echo "[??]   ./dockerrun.sh -n my_svr -w my_net"
  echo ""
  exit
}


##################
# main procedure #
##################

# create required folders
mkdir -p "$LOGDIR" &> /dev/null
mkdir -p "$DD" &> /dev/null

echo ""
echo "[--]" | tee $LOGFILE
echo "[>>] $CONTAINER: dockerrun.sh script [$(date +%Y/%m/%d-%H:%M:%S)]" | tee -a $LOGFILE
echo "[--]" | tee -a $LOGFILE

if [ -d $DC ]; then
  cd "$DC"
  get_params $@
  chk_params

  # check running container
  if ( chk_container $CTN_NAME ); then
    echo "[--] $CTN_NAME is already in use, please remove the existing container first" | tee -a $LOGFILE
    exit
    # main process to build up container
  else
    # create image
    if [ -f "Dockerfile" ]; then
      echo "[>>] Building up docker image ($CONTAINER)..." | tee -a $LOGFILE
      docker build -t $CONTAINER .
      if ( chk_image $CONTAINER ); then
        # prepare container options
        OPT1="--name $CTN_NAME -v $DD:/data"
        chk_network $NET
        if [ ! "$NET" == "" ]; then
          OPT2="--network $NET -p $H_PORT:$C_PORT -p $H_PORT:$C_PORT/udp"
        else
          OPT2="-p $H_PORT:$C_PORT -p $H_PORT:$C_PORT/udp"
        fi
        OPT3="--restart unless-stopped -d  -v $DD:/data $CONTAINER"
        echo "[@@] docker run $OPT1 $OPT2 $OPT3" | tee -a $LOGFILE
        docker run $OPT1 $OPT2 $OPT3
        # final check
        if ( chk_status $CTN_NAME ); then
          echo "[--]" | tee -a $LOGFILE
          echo "[--] Container: $CTN_NAME is ready" | tee -a $LOGFILE
          ALPINE_VER=$(docker exec $CTN_NAME grep VERSION /etc/os-release | sed 's/VERSION_ID=//')
          IPERF3_VER=$(docker exec $CTN_NAME iperf3 -v|grep -w iperf|cut -d" " -f2)
          echo "[--] Alpine Ver: $ALPINE_VER" | tee $VER
          echo "[--] iperf3 Ver: $IPERF3_VER" | tee -a $VER
          chown root.root $VER
          chmod 400 $VER
          echo "[--]" | tee -a $LOGFILE
        else
          echo "[--]" | tee -a $LOGFILE
          echo "[!!] Container: $CTN_NAME built failure" | tee -a $LOGFILE
          echo "[--]" | tee -a $LOGFILE
        fi
      else
        echo "[!!] No docker image ($CONTAINER) is built." | tee -a $LOGFILE
      fi
    else
      echo "[!!] No Dockerfile is found." | tee -a $LOGFILE
    fi
  fi
fi
echo ""
