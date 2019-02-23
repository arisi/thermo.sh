#!/bin/bash

GPIO=/sys/class/gpio
ID=28-011562c951ff
TARGET=25
HYSTERESIS=1
  
if [ ! -e /sys/bus/w1 ]; then
  echo ERROR: 1wire bus NOT detected
  exit -1
fi
if [ ! -e /sys/bus/w1/devices/$ID/w1_slave ]; then
  echo ERROR: 1wire sensor $ID NOT detected
  exit -1
fi

if [ ! -e /sys/class/gpio/gpio2/device/dev ]; then
  echo Activating GPIO2 for relay drive...
  echo 2 >$GPIO/export
  sleep 1
  if [ ! -e /sys/class/gpio/gpio2/device/dev ]; then
    echo ERROR: Failed to activate GPIO2 for relay drive
    exit -1
  fi
  echo "Done"
fi


shutdown()
{
  echo 2 >$GPIO/unexport
  echo "\nExiting... GPIO2 uninitialized"
  exit 0
}

trap shutdown SIGINT

echo "Using GPIO2 (pin 3 on header) for relay drive"
echo out >$GPIO/gpio2/direction
echo 1 >/sys/class/gpio/gpio2/value	

while [ 1 ]
do
  data=$(cat /sys/bus/w1/devices/$ID/w1_slave)
  if echo "$data" | grep -q YES; then
    if [[ $data =~ t=([0-9]+)$ ]]; then
      
      temp="$((${BASH_REMATCH[1]} / 1000))"
      echo Temperature: $temp C / $TARGET
      if (( $temp > $TARGET + $HYSTERESIS )); then
        echo over
        echo 1 >/sys/class/gpio/gpio2/value	
      elif (( $temp < $TARGET - $HYSTERESIS )); then
        echo under
        echo 0 >/sys/class/gpio/gpio2/value
      else
        echo ok
      fi
    else
      echo ERROR: No Temperature: $data
    fi
  else 
    echo ERROR: CRC: $data
  fi
  sleep 1
done

