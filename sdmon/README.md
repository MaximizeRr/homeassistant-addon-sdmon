# Home Assistant Add-on: SD Card Monitor (sdmon)

Monitor the health status of industrial-grade SD cards using sdmon.

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

## About

This add-on integrates [sdmon](https://github.com/Ognian/sdmon) into Home Assistant, allowing you to monitor the health status of your industrial-grade SD card. sdmon reads health data from compatible SD cards using CMD56 and provides detailed information about:

- Endurance remaining life percentage
- Erase counts (total, average, min, max)
- Power-on count
- Bad block information
- And more card-specific health metrics

## Supported SD Cards

Currently, sdmon supports the following industrial-grade SD cards:

- **Apacer** Industrial SD Cards
- **Kingston** Industrial SD Cards (SDCIT/32GB and SDCIT2/32GB)
- **Kingston** High Endurance SD Cards (SDCE)
- **SanDisk** Industrial SD Cards
- **Western Digital** WD Purple SD Cards (QD101)

**Note:** Not all SD cards support health status reporting. Consumer-grade SD cards typically do not support this feature.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "SD Card Monitor (sdmon)" add-on
3. Configure the add-on (see Configuration section)
4. Start the add-on
5. Check the add-on logs to verify it's working

## Configuration

```yaml
device: "/dev/mmcblk0"
scan_interval: 300
add_delay: false
output_file: "/share/sdmon_status.json"
```

### Option: `device`

The device path to your SD card. Default is `/dev/mmcblk0`.

### Option: `scan_interval`

How often to scan the SD card health status, in seconds. Default is 300 seconds (5 minutes). Valid range: 60-86400 seconds.

### Option: `add_delay`

Some Kingston cards require extra time between CMD56 commands. If sdmon fails without this option, try enabling it. Default is `false`.

### Option: `output_file`

Where to write the health status JSON output. Default is `/share/sdmon_status.json`. This file can be read by Home Assistant sensors.

## Integration with Home Assistant

The health status is written to a JSON file (default: `/share/sdmon_status.json`) that can be read by Home Assistant using the `file` sensor platform or a custom sensor.

Example sensor configuration in `configuration.yaml`:

```yaml
sensor:
  - platform: file
    name: SD Card Health
    file_path: /share/sdmon_status.json
    value_template: >
      {% if value_json.enduranceRemainLifePercent is defined %}
        {{ value_json.enduranceRemainLifePercent }}
      {% elif value_json.healthStatusPercentUsed is defined %}
        {{ 100 - value_json.healthStatusPercentUsed }}
      {% else %}
        unknown
      {% endif %}
    unit_of_measurement: '%'
```

## Support

For issues with the add-on, please [open an issue on GitHub][issues].

For issues with sdmon itself, please see the [sdmon repository][sdmon].

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[issues]: https://github.com/maximizerr/homeassistant-addon-sdmon/issues
[sdmon]: https://github.com/Ognian/sdmon

