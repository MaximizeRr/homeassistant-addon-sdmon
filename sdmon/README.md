# Home Assistant Add-on: SD Card Monitor (sdmon)

Monitor the health status of industrial-grade SD cards using sdmon.

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]

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

**Sensors are automatically created!** No manual configuration is needed.

The add-on automatically creates the following sensors in Home Assistant:

### Common Sensors (all card types)

- `sensor.sdmon_health` - Overall SD card health percentage
- `sensor.sdmon_status` - Monitoring status (ok/error)

### Apacer/Kingston Cards

- `sensor.sdmon_total_erase_count` - Total erase cycles
- `sensor.sdmon_avg_erase_count` - Average erase count
- `sensor.sdmon_max_erase_count` - Maximum erase count
- `sensor.sdmon_power_up_count` - Number of power-on cycles
- `sensor.sdmon_abnormal_poweroff_count` - Abnormal power-off events
- `sensor.sdmon_bad_block_count` - Bad block count

### SanDisk/Western Digital Cards

- `sensor.sdmon_manufacture_date` - Manufacturing date
- `sensor.sdmon_power_on_count` - Number of power-on cycles

The health status is also written to a JSON file (default: `/share/sdmon_status.json`) for advanced use cases or custom integrations.

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
