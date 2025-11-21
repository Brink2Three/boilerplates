# Prereqs
Setup ESPHome add-on in your HA: https://esphome.io/guides/getting_started_hassio/#installing-esphome-device-builder


# TLDR hardware guide:

Esp32 pin out:

Vusb (3.3 or 5v) bus to:
 - CCS-811@VCC,
 - DHT11@VCC

ESP@Gnd to:
 - CCS-811@GND
 - CCS-811@WAKE
 - DHT11@GND

Data pins:

ESP side | to | part side

- GPIO 25 (A1) to DHT11@S (Data/sense)
- GPIO 21 (SDA) TO CCS-811@SDA
- GPIO 22 (SCL) TO CCS-811@SCL

**See Reference photos for pinouts and examples**


# References: 
- hardware connection reference: https://www.instructables.com/Connected-Weather-Station-With-ESP32/
- Board in use: https://www.sparkfun.com/sparkfun-thing-plus-esp32-wroom-micro-b.html
- Sensors in use: 
    - DHT 11: https://www.microcenter.com/product/618777/inland-dht11-temperature-humidity-moisture-sensor-module
    - CCS-811: https://www.microcenter.com/product/632703/inland-ccs811-air-quality-sensor-module

# If you need to flash espohome manually...
flashing esphome to sparkfun32: https://github.com/esphome/esphome-flasher/releases

Better flasher for regular ESP32s: https://web.esphome.io/

# Once the device is conencted...
Once you see it in ESPhome, select the device and add the yaml config content from livingroom32. Adjusting the secret variables to match your configuration. 