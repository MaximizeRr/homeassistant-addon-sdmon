#!/usr/bin/with-contenv bashio
# ==============================================================================
# Update Home Assistant sensors with sdmon data
# ==============================================================================

# Get the JSON data from stdin or file
if [ -p /dev/stdin ]; then
    json_data=$(cat)
else
    json_data="$1"
fi

# Get Home Assistant configuration
ha_url="http://supervisor/core/api"
token="${SUPERVISOR_TOKEN}"

# Function to create/update a sensor with proper device linkage
update_sensor() {
    local entity_id="$1"
    local state="$2"
    local attributes="$3"
    local unit="$4"
    local state_class="$5"
    local device_class="$6"
    local icon="$7"

    local payload
    payload=$(jq -n \
        --arg state "$state" \
        --arg unit "$unit" \
        --arg state_class "$state_class" \
        --arg device_class "$device_class" \
        --arg icon "$icon" \
        --argjson attributes "$attributes" \
        --argjson device_info "$device_info_json" \
        '{
            state: $state,
            attributes: ($attributes + $device_info + {
                unit_of_measurement: (if $unit != "" then $unit else null end),
                state_class: (if $state_class != "" then $state_class else null end),
                device_class: (if $device_class != "" then $device_class else null end),
                icon: $icon,
                friendly_name: $attributes.friendly_name
            } | with_entries(select(.value != null and .value != "")))
        }')

    response=$(curl -sSL -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "${payload}" \
        "${ha_url}/states/${entity_id}" 2>&1)

    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        bashio::log.debug "Updated sensor ${entity_id}: ${state}"
        return 0
    else
        bashio::log.warning "Failed to update sensor ${entity_id} (HTTP ${http_code})"
        return 1
    fi
}

# Parse JSON and extract values
success=$(echo "$json_data" | jq -r '.success // false')
device=$(echo "$json_data" | jq -r '.device // "unknown"')
version=$(echo "$json_data" | jq -r '.version // "unknown"')

# Extract and format flashId as unique identifier
# flashId is burned into the device and serves as a unique identifier per the HA entity registry docs
flash_id_array=$(echo "$json_data" | jq -r '.flashId // empty')
if [ -n "$flash_id_array" ]; then
    # Convert array like ["0x98","0x3c",...] to string like "983c98b3f6e3081e00"
    flash_id=$(echo "$flash_id_array" | jq -r 'map(ltrimstr("0x")) | join("")' | tr '[:upper:]' '[:lower:]')
    bashio::log.info "SD Card Flash ID: ${flash_id}"
else
    # Fallback to device name if no flashId available
    flash_id=$(echo "$device" | sed 's/\//_/g')
    bashio::log.warning "No flashId found, using device as identifier: ${flash_id}"
fi

# Extract device information for proper device registry integration
# Per HA docs: https://developers.home-assistant.io/docs/device_registry_index
manufacturer=$(echo "$json_data" | jq -r '.productMarker // empty' | head -c 20)
if [ -z "$manufacturer" ]; then
    manufacturer="Unknown"
fi

# Extract hardware and firmware versions
ic_version=$(echo "$json_data" | jq -r '.icVersion // empty')
fw_version=$(echo "$json_data" | jq -r '.fwVersion // empty')
hw_version=""
sw_version=""
if [ -n "$ic_version" ]; then
    hw_version=$(echo "$ic_version" | jq -r 'map(.) | join(".")' 2>/dev/null || echo "")
fi
if [ -n "$fw_version" ]; then
    sw_version=$(echo "$fw_version" | jq -r 'map(.) | join(".")' 2>/dev/null || echo "")
fi

# Create device info object that will be included in all sensors
# This groups all sensors under the same device in Home Assistant
device_info_json=$(jq -n \
    --arg flash_id "$flash_id" \
    --arg device "$device" \
    --arg manufacturer "$manufacturer" \
    --arg model "Industrial SD Card" \
    --arg hw_version "$hw_version" \
    --arg sw_version "$sw_version" \
    --arg version "$version" \
    '{
        device: {
            identifiers: [$flash_id],
            name: ("SD Card " + $device),
            manufacturer: $manufacturer,
            model: $model,
            hw_version: (if $hw_version != "" then $hw_version else null end),
            sw_version: (if $sw_version != "" then $sw_version else $version end),
            via_device: "sdmon_addon"
        }
    } | with_entries(select(.value != null and .value != ""))')

# Check if the scan was successful
if [ "$success" != "true" ]; then
    bashio::log.warning "sdmon scan was not successful, not updating sensors"

    # Update status sensor to show error (extract flashId even on error if available)
    error_msg=$(echo "$json_data" | jq -r '.error // "Unknown error"')
    flash_id_error=$(echo "$json_data" | jq -r '.flashId // empty')
    if [ -n "$flash_id_error" ]; then
        flash_id=$(echo "$flash_id_error" | jq -r 'map(ltrimstr("0x")) | join("")' | tr '[:upper:]' '[:lower:]')
    else
        flash_id=$(echo "$device" | sed 's/\//_/g')
    fi
    update_sensor "sensor.sdmon_status" "error" \
        "$(jq -n --arg error "$error_msg" --arg uid "$flash_id" '{friendly_name: "SD Monitor Status", unique_id: $uid, error: $error}')" \
        "" "" "" "mdi:alert-circle"
    exit 0
fi

# Determine card type and extract appropriate metrics
endurance=$(echo "$json_data" | jq -r '.enduranceRemainLifePercent // empty')
health_used=$(echo "$json_data" | jq -r '.healthStatusPercentUsed // empty')

# Main health sensor
if [ -n "$endurance" ]; then
    # Apacer/Kingston style
    health_percent="$endurance"
    health_type="endurance"
else
    # SanDisk/WD style - convert used to remaining
    health_percent=$(echo "100 - $health_used" | bc)
    health_type="health"
fi

# Update main health sensor with proper sensor attributes
# Per HA docs: state_class for sensors that represent a measurement
update_sensor "sensor.sdmon_health" "$health_percent" \
    "$(jq -n --arg type "$health_type" --arg uid "$flash_id" '{friendly_name: "Health", unique_id: $uid, card_type: $type}')" \
    "%" "measurement" "" "mdi:sd"

# Update status sensor
update_sensor "sensor.sdmon_status" "ok" \
    "$(jq -n --arg uid "$flash_id" '{friendly_name: "Status", unique_id: ($uid + "_status"), last_scan: (now | strftime("%Y-%m-%d %H:%M:%S"))}')" \
    "" "" "" "mdi:check-circle"

# Extract and update specific metrics based on card type
if [ -n "$endurance" ]; then
    # Apacer/Kingston metrics
    total_erase=$(echo "$json_data" | jq -r '.totalEraseCount // 0')
    avg_erase=$(echo "$json_data" | jq -r '.avgEraseCount // 0')
    max_erase=$(echo "$json_data" | jq -r '.maxEraseCount // 0')
    power_up=$(echo "$json_data" | jq -r '.powerUpCount // 0')
    abnormal_poweroff=$(echo "$json_data" | jq -r '.abnormalPowerOffCount // 0')
    bad_blocks=$(echo "$json_data" | jq -r '.laterBadBlockCount // 0')

    update_sensor "sensor.sdmon_total_erase_count" "$total_erase" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Total Erase Count", unique_id: ($uid + "_total_erase")}')" \
        "cycles" "total_increasing" "" "mdi:counter"

    update_sensor "sensor.sdmon_avg_erase_count" "$avg_erase" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Average Erase Count", unique_id: ($uid + "_avg_erase")}')" \
        "cycles" "measurement" "" "mdi:counter"

    update_sensor "sensor.sdmon_max_erase_count" "$max_erase" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Max Erase Count", unique_id: ($uid + "_max_erase")}')" \
        "cycles" "measurement" "" "mdi:counter"

    update_sensor "sensor.sdmon_power_up_count" "$power_up" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Power-On Count", unique_id: ($uid + "_power_up")}')" \
        "cycles" "total_increasing" "" "mdi:power"

    update_sensor "sensor.sdmon_abnormal_poweroff_count" "$abnormal_poweroff" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Abnormal Power-Off Count", unique_id: ($uid + "_abnormal_poweroff")}')" \
        "events" "total_increasing" "" "mdi:power-plug-off"

    update_sensor "sensor.sdmon_bad_block_count" "$bad_blocks" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Bad Block Count", unique_id: ($uid + "_bad_blocks")}')" \
        "blocks" "measurement" "" "mdi:close-circle"
else
    # SanDisk/WD metrics
    manufacture_date=$(echo "$json_data" | jq -r '.manufactureYYMMDD // "unknown"')
    power_on_times=$(echo "$json_data" | jq -r '.powerOnTimes // 0')

    update_sensor "sensor.sdmon_manufacture_date" "$manufacture_date" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Manufacture Date", unique_id: ($uid + "_manufacture_date")}')" \
        "" "" "" "mdi:calendar"

    update_sensor "sensor.sdmon_power_on_count" "$power_on_times" \
        "$(jq -n --arg uid "$flash_id" '{friendly_name: "Power-On Count", unique_id: ($uid + "_power_on")}')" \
        "cycles" "total_increasing" "" "mdi:power"
fi

bashio::log.info "Successfully updated Home Assistant sensors"

