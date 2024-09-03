#!/bin/bash

# Define file names
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SSID_LIST_FILE="ssids.txt"
BSSID_OUTPUT_FILE="bssids.txt"
LOCKFILE="/tmp/monitoring.lock"

# Paths to the scripts
GET_BSSIDS_SCRIPT="$SCRIPT_DIR/get_bssids.py"
MONITOR_BSSIDS_SCRIPT="$SCRIPT_DIR/monitor_bssids.sh"

# Flag to track if NetworkManager needs to be restarted
NEEDS_NETWORK_RESTART=false

# Function to remove the lock file on exit and restart NetworkManager if needed
cleanup() {
    rm -f "$LOCKFILE"
    if [ "$NEEDS_NETWORK_RESTART" = true ]; then
        echo "Restarting NetworkManager..."
        sudo service NetworkManager start > /dev/null 2>&1
        echo "NetworkManager restarted."
    fi
    exit
}

# Function to find and set the monitorable interface
find_and_set_monitor_interface() {
    # Run airmon-ng check kill to stop interfering processes
    sudo airmon-ng check kill > /dev/null 2>&1
    NEEDS_NETWORK_RESTART=true

    interfaces=$(iw dev | grep -oP 'Interface \K\w+')

    for iface in $interfaces; do
        # Check if a monitor mode interface already exists
        if [[ $iface == *mon ]]; then
            echo "$iface"
            return
        fi

        # Try to put the interface into monitor mode
        sudo airmon-ng start "$iface" > /dev/null 2>&1

        # Check if the monitor mode interface was created
        if iw dev | grep -q "${iface}mon"; then
            echo "${iface}mon"
            return
        else
            echo "Failed to set $iface to monitor mode. Skipping..."
        fi
    done

    echo "No suitable wireless interface found or failed to set monitor mode." >&2
    exit 1
}

# Function to check if a script is executable
check_executable() {
    local script="$1"
    if [ ! -x "$script" ]; then
        echo "Error: $script is not executable."
        echo "Attempting to make it executable..."
        chmod +x "$script"
        if [ ! -x "$script" ]; then
            echo "Failed to make $script executable. Exiting."
            exit 1
        else
            echo "$script is now executable."
        fi
    fi
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

# Check if the scripts are executable
check_executable "$GET_BSSIDS_SCRIPT"
check_executable "$MONITOR_BSSIDS_SCRIPT"

# Find and set the monitorable interface
INTERFACE=$(find_and_set_monitor_interface)
echo "Using interface: $INTERFACE"

# Step 1: Run the Python script to get BSSIDs and Channels
echo "Running Python script to retrieve BSSIDs and Channels..."
sudo python3 "$GET_BSSIDS_SCRIPT" "$SSID_LIST_FILE" "$BSSID_OUTPUT_FILE" "$INTERFACE"

echo "BSSIDs and Channels retrieved successfully."

# Step 2: Run the Bash script to monitor BSSIDs
echo "Starting monitoring of BSSIDs..."
sudo "$MONITOR_BSSIDS_SCRIPT" "$INTERFACE"

echo "Monitoring complete."

# Cleanup lock file and restart NetworkManager after successful completion
cleanup
