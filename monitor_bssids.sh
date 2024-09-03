#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

BSSID_FILE="$SCRIPT_DIR/bssids.txt"
INTERFACE="$1"
OUTPUT_FILE="$SCRIPT_DIR/monitoring_results.txt"
LOG_FILE="$SCRIPT_DIR/monitoring.log"

# Function to log messages with timestamps
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to monitor BSSIDs
monitor_bssids() {
    log_message "Starting monitoring of BSSIDs using interface $INTERFACE..."
    echo "Monitoring started at $(date)" > "$OUTPUT_FILE"

    while IFS= read -r line; do
        SSID=$(echo "$line" | cut -d ':' -f 1)
        BSSID=$(echo "$line" | cut -d ',' -f 1 | cut -d ' ' -f 2)
        CHANNEL=$(echo "$line" | cut -d ',' -f 2 | cut -d ' ' -f 3)

        log_message "Monitoring BSSID $BSSID (SSID: $SSID) on Channel $CHANNEL using $INTERFACE..."

        while true; do
            sudo airodump-ng -c "$CHANNEL" --bssid "$BSSID" -w "$SCRIPT_DIR/$SSID-psk" "$INTERFACE" > /dev/null 2>&1

            # Check if a handshake was captured or BSSID was detected
            if [ -f "$SCRIPT_DIR/$SSID-psk-01.csv" ]; then
                BSSID_INFO=$(grep "$BSSID" "$SCRIPT_DIR/$SSID-psk-01.csv")

                if [ -n "$BSSID_INFO" ]; then
                    SIGNAL=$(echo "$BSSID_INFO" | cut -d ',' -f 9 | tr -d ' ')
                    log_message "BSSID $BSSID (SSID: $SSID) detected with signal strength: $SIGNAL dBm"
                    break
                else:
                    log_message "BSSID $BSSID (SSID: $SSID) not detected, retrying..."
                fi

                # Clean up the output file after each scan
                rm "$SCRIPT_DIR/$SSID-psk-01.csv"
            else:
                log_message "No capture file generated, check your setup."
            fi
        done

    done < "$BSSID_FILE"

    log_message "Monitoring complete."
}

# Start monitoring
monitor_bssids
