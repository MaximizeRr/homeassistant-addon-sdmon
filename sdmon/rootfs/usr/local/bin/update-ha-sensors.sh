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

# Function to create/update a sensor
update_sensor() {
    local entity_id="$1"
    local state="$2"
    local attributes="$3"
    local unit="$4"
    local device_class="$5"
    local icon="$6"

    local payload
    payload=$(jq -n \
        --arg state "$state" \
        --arg unit "$unit" \
        --arg device_class "$device_class" \
        --arg icon "$icon" \
        --argjson attributes "$attributes" \
        '{
            state: $state,
            attributes: ($attributes + {
                unit_of_measurement: $unit,
                device_class: $device_class,
                icon: $icon,
                friendly_name: $attributes.friendly_name
            })
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

# Check if the scan was successful
if [ "$success" != "true" ]; then
    bashio::log.warning "sdmon scan was not successful, not updating sensors"

    # Update status sensor to show error
    error_msg=$(echo "$json_data" | jq -r '.error // "Unknown error"')
    update_sensor "sensor.sdmon_status" "error" \
        "$(jq -n --arg error "$error_msg" --arg device "$device" '{friendly_name: "SD Card Monitor Status", error: $error, device: $device}')" \
        "" "" "mdi:alert-circle"
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

# Update main health sensor
update_sensor "sensor.sdmon_health" "$health_percent" \
    "$(echo "$json_data" | jq --arg type "$health_type" '{friendly_name: "SD Card Health", card_type: $type, device: .device, version: .version}')" \
    "%" "" "mdi:sd"

# Update status sensor
update_sensor "sensor.sdmon_status" "ok" \
    "$(echo "$json_data" | jq '{friendly_name: "SD Card Monitor Status", device: .device, version: .version, last_update: (now | strftime("%Y-%m-%d %H:%M:%S"))}')" \
    "" "" "mdi:check-circle"

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
        "$(jq -n '{friendly_name: "SD Card Total Erase Count"}')" \
        "cycles" "" "mdi:counter"

    update_sensor "sensor.sdmon_avg_erase_count" "$avg_erase" \
        "$(jq -n '{friendly_name: "SD Card Average Erase Count"}')" \
        "cycles" "" "mdi:counter"

    update_sensor "sensor.sdmon_max_erase_count" "$max_erase" \
        "$(jq -n '{friendly_name: "SD Card Max Erase Count"}')" \
        "cycles" "" "mdi:counter"

    update_sensor "sensor.sdmon_power_up_count" "$power_up" \
        "$(jq -n '{friendly_name: "SD Card Power-On Count"}')" \
        "cycles" "" "mdi:power"

    update_sensor "sensor.sdmon_abnormal_poweroff_count" "$abnormal_poweroff" \
        "$(jq -n '{friendly_name: "SD Card Abnormal Power-Off Count"}')" \
        "events" "" "mdi:power-plug-off"

    update_sensor "sensor.sdmon_bad_block_count" "$bad_blocks" \
        "$(jq -n '{friendly_name: "SD Card Bad Block Count"}')" \
        "blocks" "" "mdi:close-circle"
else
    # SanDisk/WD metrics
    manufacture_date=$(echo "$json_data" | jq -r '.manufactureYYMMDD // "unknown"')
    power_on_times=$(echo "$json_data" | jq -r '.powerOnTimes // 0')

    update_sensor "sensor.sdmon_manufacture_date" "$manufacture_date" \
        "$(jq -n '{friendly_name: "SD Card Manufacture Date"}')" \
        "" "" "mdi:calendar"

    update_sensor "sensor.sdmon_power_on_count" "$power_on_times" \
        "$(jq -n '{friendly_name: "SD Card Power-On Count"}')" \
        "cycles" "" "mdi:power"
fi

bashio::log.info "Successfully updated Home Assistant sensors"

