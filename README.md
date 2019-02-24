# Thermo.sh -- Thermostat in Bash

Simple as it can be: no dependencies, nothing to install on vanilla raspbian OS.

## Hardware Preparations:

### Relay

You can use any available pin you want for relay control: the script will try
to configure the chosen pin as output.

### 1Wire 

You need to configure 1wire bus as usual by adding this line to file `/boot/config.txt` :

`dtoverlay=w1-gpio,gpiopin=x`

replacing the x with your chosen 1wire pin. Reboot required.

## Hardware Configuration:

### Relay

Set environment variable `THERMO_RELAY_PIN` to pin number chosen. Default is pin 2.

And use `THERMO_RELAY_ACTIVE` to define the active state: 0 => relay pulls
when pin is low and 1=> opposite.

### 1Wire 

Set environment variable `THERMO_ADDR` to sensor address chosen. There is no default.

You can run the `./thermo.sh` with no sensor config: it will list the available sensors so 
you can pick one of them:

```console
thermo.sh : Simple temperature controller for Raspberry PI

Config: (use environment variables to adjust)
 THERMO_ADDR:            1WIRE Sensor Address:  
 THERMO_RELAY_PIN:       Relay pin:             2
 THERMO_RELAY_ACTIVE:    Relay Active State:    0
 THERMO_TARGET:          Target Temperature:    25

ERROR: No 1WIRE address provided!

Please set it with environment variable, eg:
THERMO_ADDR=28-011562c951ff RELAY_PIN=2 ./thermo.sh

Detected sensors:
28-011562c951ff

Pick one of them and run: THERMO_ADDR=xxx ./thermo.sh

```


## Thermostat Configuration:

Set environment variable `THERMO_TARGET` to the target temperature. Default is 25C.

## Running

Just run the script:

```console

$ THERMO_ADDR=28-011562c951ff ./thermo.sh

thermo.sh : Simple temperature controller for Raspberry PI

Config: (use environment variables to adjust)
 THERMO_ADDR:            1WIRE Sensor Address:  28-011562c951ff
 THERMO_RELAY_PIN:       Relay pin:             2
 THERMO_RELAY_ACTIVE:    Relay Active State:    0
 THERMO_TARGET:          Target Temperature:    25

Temperature: 21 C / Target: 25 / Relay: on / State: UNDER
Temperature: 21 C / Target: 25 / Relay: on / State: UNDER

\nExiting.
$

```


