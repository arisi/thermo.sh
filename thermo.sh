#!/bin/bash

###
#
# thermo.sh
#
# A simple shell script for temperature control with Raspberry PI and DS1820 ONEWIRE sensor
#
# Written by Ari Siitonen (jalopuuverstas@gmail.com) 2019
#
# https://github.com/arisi/thermo.sh
#
###

ADDR=${THERMO_ADDR}
RELAY_PIN=${THERMO_RELAY_PIN:-2}
RELAY_ACTIVE=${THERMO_RELAY_ACTIVE:-0}
TARGET=${THERMO_TARGET:-25}

ONEWIRE=/sys/bus/w1/devices
GPIO=/sys/class/gpio
RELAY=gpio$RELAY_PIN
HYSTERESIS=1
RELAY_STATE="?"
echo
echo "thermo.sh : Simple temperature controller for Raspberry PI"
echo
echo "Config: (use environment variables to adjust)"
echo " THERMO_ADDR:            1WIRE Sensor Address:  $ADDR"
echo " THERMO_RELAY_PIN:       Relay pin:             $RELAY_PIN"
echo " THERMO_RELAY_ACTIVE:    Relay Active State:    $RELAY_ACTIVE"
echo " THERMO_TARGET:          Target Temperature:    $TARGET"
echo


if [ ! -e /sys/bus/w1 ]; then
  echo "ERROR: ONEWIRE bus NOT detected"
  exit -1
fi

if [ ! -e $ONEWIRE/$ADDR/w1_slave ]; then
  if [ "$ADDR" == "" ]; then
    echo "ERROR: No ONEWIRE address provided!"
  else
    echo "ERROR: ONEWIRE sensor $ADDR NOT detected"
  fi
  echo
  echo "Please set it with environment variable, eg:"
  echo "ID=28-011562c951ff RELAY_PIN=2 ./thermo.sh"
  echo
  echo "Detected sensors:"
  ls $ONEWIRE |grep '^[1-9][0-9]-'
  echo
  echo "Pick one of them and run: THERMO_ADDR=xxx ./thermo.sh"
  exit -1
fi

configRelay() {
  if [ ! -e $GPIO/$RELAY/device/dev ]; then
    echo $RELAY_PIN >$GPIO/export
    sleep 1
    if [ ! -e $GPIO/$RELAY/device/dev ]; then
      echo "ERROR: Failed to activate $RELAY for relay drive"
      exit -1
    fi
  fi
  echo out >$GPIO/$RELAY/direction
}

setRelay() {
  if [ "$1" != "$RELAY_STATE" ]; then
    if [ "$1" == "off" ]; then
      echo $(( ! $RELAY_ACTIVE )) >$GPIO/$RELAY/value
    else
      echo $RELAY_ACTIVE >$GPIO/$RELAY/value
    fi
    RELAY_STATE=$1
  fi
}

shutdown() {
  echo $RELAY_PIN >$GPIO/unexport
  echo "\nExiting."
  exit 0
}
trap shutdown SIGINT

configRelay
setRelay off

while [ 1 ]
do
  data=$(cat $ONEWIRE/$ADDR/w1_slave)
  if echo "$data" | grep -q YES; then
    if [[ $data =~ t=([0-9]+)$ ]]; then
      temp="$((${BASH_REMATCH[1]} / 1000))"
      info="ok"
      if (( $temp > $TARGET + $HYSTERESIS )); then
        info="OVER"
        setRelay off
      elif (( $temp < $TARGET - $HYSTERESIS )); then
        info="UNDER"
        setRelay on
      fi
      echo "Temperature: $temp C / Target: $TARGET / Relay: $RELAY_STATE / State: $info"
    else
      echo "ERROR: No Temperature: $data"
    fi
  else
    echo "ERROR: CRC: $data"
  fi
  sleep 1
done
