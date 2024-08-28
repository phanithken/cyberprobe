#!/bin/bash

# Define file names
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SSID_LIST_FILE="ssids.txt"
BSSID_OUTPUT_FILE="bssids.txt"
INTERFACE="wlan0mon"
LOCKFILE="/tmp/monitoring.lock"

# Function to remove the lock file on exit
cleanup() {
    rm -f "$LOCKFILE"
    exit
}

# Check if the lock file exists
if [ -e "$LOCKFILE" ]; then
    echo "Monitoring script is already running. Exiting."
    exit 1
fi

# Create a lock file
touch "$LOCKFILE"

# Trap exit signals to ensure the lock file is removed if the script is interrupted
trap cleanup INT TERM EXIT

# Step 1: Run the Python script to get BSSIDs and Channels
echo "Running Python script to retrieve BSSIDs and Channels..."
sudo python3 "$SCRIPT_DIR/get_bssids.py" "$SSID_LIST_FILE" "$BSSID_OUTPUT_FILE" "$INTERFACE"

echo "BSSIDs and Channels retrieved successfully."

# Step 2: Run the Bash script to monitor BSSIDs
echo "Starting monitoring of BSSIDs..."
sudo "$SCRIPT_DIR/monitor_bssids.sh"

echo "Monitoring complete."

# Cleanup lock file after successful completion
cleanup