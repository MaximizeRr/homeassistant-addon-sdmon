# Home Assistant Add-on: SD Card Monitor (sdmon)

## How to use

This add-on monitors the health status of industrial-grade SD cards by periodically running sdmon and writing the results to a JSON file.

### Basic Setup

1. **Install the add-on** - Install from the add-on store
2. **Configure the device** - By default it monitors `/dev/mmcblk0`
3. **Start the add-on** - The add-on will begin monitoring immediately
4. **Check the logs** - Verify that the monitoring is working correctly

### Configuration Options

The add-on provides several configuration options:

#### Device Path

```yaml
device: "/dev/mmcblk0"
```

This is the path to your SD card device. On Raspberry Pi systems, the SD card is typically `/dev/mmcblk0`. If you have multiple SD cards or want to monitor a different device, change this path accordingly.

#### Scan Interval

```yaml
scan_interval: 300
```

How often (in seconds) to check the SD card health. The default is 300 seconds (5 minutes). You can set this anywhere from 60 seconds (1 minute) to 86400 seconds (24 hours).

- **Lower values** = More frequent monitoring, more detailed history, but more wear on the card
- **Higher values** = Less frequent monitoring, less wear, but you may miss short-term issues

For most use cases, 300-600 seconds is a good balance.

#### Add Delay

```yaml
add_delay: false
```

Some SD cards (particularly certain Kingston models) require an extra 1-second delay between CMD56 commands. If sdmon reports timeout errors or fails to read your card:

1. First try running without this option (default `false`)
2. If it fails, enable this option by setting it to `true`
3. Check the logs again to see if it now works

#### Output File

```yaml
output_file: "/share/sdmon_status.json"
```

The path where the health status JSON will be written. The default location (`/share/`) is accessible to Home Assistant and other add-ons.

You can change this to:

- `/share/sdmon_status.json` (default, accessible system-wide)
- `/config/sdmon_status.json` (stored with your configuration)

### Understanding the Output

The add-on writes a JSON file with health information. The format depends on your SD card manufacturer:

#### Apacer/Kingston Cards

```json
{
  "version": "v0.9.0",
  "device": "/dev/mmcblk0",
  "enduranceRemainLifePercent": 99.97,
  "totalEraseCount": 1380,
  "avgEraseCount": 1,
  "maxEraseCount": 5,
  "powerUpCount": 55,
  "abnormalPowerOffCount": 0,
  "laterBadBlockCount": 0,
  "success": true
}
```

Key fields:

- `enduranceRemainLifePercent` - Percentage of life remaining (100% = new, 0% = worn out)
- `totalEraseCount` - Total number of erase operations
- `powerUpCount` - Number of times the card has been powered on
- `abnormalPowerOffCount` - Number of improper shutdowns

#### SanDisk/Western Digital Cards

```json
{
  "version": "v0.9.0",
  "device": "/dev/mmcblk0",
  "healthStatusPercentUsed": 1,
  "manufactureYYMMDD": "240403",
  "powerOnTimes": 14,
  "success": true
}
```

Key fields:

- `healthStatusPercentUsed` - Percentage of life used (0% = new, 100% = worn out)
- `manufactureYYMMDD` - Manufacturing date
- `powerOnTimes` - Number of power-on cycles

### Integrating with Home Assistant

**No configuration needed!** The add-on automatically creates sensors in Home Assistant.

#### Automatic Sensors

Once the add-on starts, it will automatically create sensors based on your SD card type:

##### Common Sensors (all card types)

- **`sensor.sdmon_health`** - Overall SD card health percentage (0-100%)
- **`sensor.sdmon_status`** - Monitoring status (ok/error)

##### Apacer/Kingston Cards

These cards provide detailed endurance metrics:

- **`sensor.sdmon_total_erase_count`** - Total erase cycles performed
- **`sensor.sdmon_avg_erase_count`** - Average erase count per block
- **`sensor.sdmon_max_erase_count`** - Maximum erase count of any block
- **`sensor.sdmon_power_up_count`** - Number of power-on cycles
- **`sensor.sdmon_abnormal_poweroff_count`** - Abnormal power-off events detected
- **`sensor.sdmon_bad_block_count`** - Count of bad blocks

##### SanDisk/Western Digital Cards

These cards provide different metrics:

- **`sensor.sdmon_manufacture_date`** - Manufacturing date (YYMMDD format)
- **`sensor.sdmon_power_on_count`** - Number of power-on cycles

#### Advanced: Manual File Sensor (Optional)

If you prefer to create custom sensors, the data is also available in a JSON file. Add to your `configuration.yaml`:

```yaml
sensor:
  - platform: file
    name: SD Card Health Custom
    file_path: /share/sdmon_status.json
    value_template: >
      {% if value_json.enduranceRemainLifePercent is defined %}
        {{ value_json.enduranceRemainLifePercent }}
      {% elif value_json.healthStatusPercentUsed is defined %}
        {{ 100 - value_json.healthStatusPercentUsed }}
      {% else %}
        unknown
      {% endif %}
    unit_of_measurement: "%"
```

### Creating Alerts

You can create automations to alert you when SD card health is low:

```yaml
automation:
  - alias: "SD Card Health Low Alert"
    trigger:
      - platform: numeric_state
        entity_id: sensor.sdmon_health
        below: 20
    action:
      - service: notify.notify
        data:
          title: "⚠️ SD Card Health Warning"
          message: "SD card health is below 20%. Consider replacing soon."

  - alias: "SD Card Abnormal Power-Off Alert"
    trigger:
      - platform: state
        entity_id: sensor.sdmon_abnormal_poweroff_count
    condition:
      - condition: template
        value_template: "{{ trigger.to_state.state | int > trigger.from_state.state | int }}"
    action:
      - service: notify.notify
        data:
          title: "⚠️ SD Card Warning"
          message: "Abnormal power-off detected. Ensure proper shutdown procedures."
```

### Troubleshooting

#### "Device not found" error

- Verify the device path is correct (check `/dev/` for available devices)
- Ensure the device is specified in the add-on configuration
- Make sure privileged mode and device access are enabled

#### "Operation timed out" errors

- Try enabling the `add_delay` option
- Your SD card may not support health status reporting
- Check if your card is on the supported list

#### "success": false in output

- Your SD card may not support CMD56 health reporting
- Consumer-grade cards typically don't support this feature
- Try with the `-a` (add_delay) option enabled

#### No data in Home Assistant sensors

- Check the add-on logs to see if sensors are being updated successfully
- Verify that the add-on has `homeassistant_api: true` enabled in config
- The sensors should appear automatically after the first successful scan
- If sensors don't appear, restart the add-on
- Check for any API errors in the add-on logs

## Support

For more information:

- [sdmon GitHub repository](https://github.com/Ognian/sdmon)
- [Home Assistant Add-on Development](https://developers.home-assistant.io/docs/add-ons)

If you encounter issues, please check the add-on logs first, then [open an issue](https://github.com/maximizerr/homeassistant-addon-sdmon/issues).
