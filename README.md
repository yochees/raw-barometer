# Raw Barometer

Connect IQ glance for the fenix 8. It shows the raw (station) pressure in hPa:
the value the sensor measures, not reduced to sea level and not corrected for
altitude. Layout follows the stock Barometer glance; START opens a full view
with the trend graph (START / DOWN / UP change the period: 4, 12, 24 hours).

Value source, first one that has data: `Activity.Info.rawAmbientPressure`,
`Sensor.Info.pressure`, `Activity.Info.ambientPressure`, last
`SensorHistory` pressure sample. The graph uses `SensorHistory` pressure.

## Build and push

```sh
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2"
"$SDK/bin/monkeyc" -o bin/RawBaro.prg -f monkey.jungle -y developer_key.der -d fenix8solar51mm -r
~/Code/garmin/tools/mtp-push bin/RawBaro.prg RawBaro.prg   # quit Garmin Express first
```

Simulator: Settings > Glance Launch Mode switches between the glance and the
full view.
