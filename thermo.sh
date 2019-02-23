#!/bin/bash


RELAY_PIN=${RELAY_PIN:-2}
RELAY_ACTIVE=${RELAY_ACTIVE:-0}
TARGET=${TARGET:-25}

GPIO=/sys/class/gpio
RELAY=gpio$RELAY_PIN
HYSTERESIS=1
RELAY_STATE="?"

echo "thermo.sh : Simple temperature controller for Raspberry PI"
echo 
echo "Config: (use environment variables to adjust)"
echo " ID:            1wire sensor address:  $ID"
echo " RELAY_PIN:     Relay pin:             $RELAY_PIN"
echo " RELAY_ACTIVE:  Active state:          $RELAY_ACTIVE"
echo " TARGET:        Target temperature:    $TARGET"
echo

if [ ! -e /sys/bus/w1 ]; then
  echo ERROR: 1wire bus NOT detected
  exit -1
fi
if [ ! -e /sys/bus/w1/devices/$ID/w1_slave ]; then
  echo ERROR: 1wire sensor $ID NOT detected
  exit -1
fi

if [ ! -e /sys/class/gpio/$RELAY/device/dev ]; then
  echo $RELAY_PIN >$GPIO/export
  sleep 1
  if [ ! -e /sys/class/gpio/$RELAY/device/dev ]; then
    echo ERROR: Failed to activate $RELAY for relay drive
    exit -1
  fi
fi

shutdown() {
  echo 2 >$GPIO/unexport
  echo "\nExiting."
  exit 0
}
trap shutdown SIGINT


setRelay() {
  if [ "$1" != "$RELAY_STATE" ]; then
    if [ "$1" == "off" ]; then 
      echo $(( ! $RELAY_ACTIVE )) >$GPIO/$RELAY/value
    else
      echo $RELAY_ACTIVE >$GPIO/$RELAY/value    
    fi
    RELAY_STATE=$1
    echo Set Relay $1 
  fi
}


echo out >$GPIO/$RELAY/direction
setRelay off

while [ 1 ]
do
  data=$(cat /sys/bus/w1/devices/$ID/w1_slave)
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
      echo Temperature: $temp C / Target: $TARGET / Relay: $RELAY_STATE / State: $info
    else
      echo ERROR: No Temperature: $data
    fi
  else
    echo ERROR: CRC: $data
  fi
  sleep 1
done
