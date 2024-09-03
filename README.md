# pkcy

This repository contains scripts to automate the process of scanning wireless networks, retrieving BSSIDs and channels, and monitoring those BSSIDs using a wireless adapter in monitor mode.

## Disclaimer

**Important:** This tool is intended for legal and ethical use only. It is created for security researchers who have explicit permission from the network owner to scan and monitor wireless networks. Unauthorized access to wireless networks is illegal and can result in severe legal consequences. The use of this tool is solely the responsibility of the user, and the creator of this script assumes no responsibility for any misuse or illegal activity carried out with this tool. Users must take full responsibility for ensuring they comply with all applicable laws and regulations.

## Scripts

### 1. `get_bssids.py`

- **Description:** This Python script scans for BSSIDs corresponding to a list of SSIDs provided in a file. It saves the BSSIDs and their channels to an output file.
- **Usage:**
  ```bash
  python3 get_bssids.py <ssid_list_file> <bssid_output_file> <interface>
  ```
  * Arguments
    * `<ssid_list_file>`: The file containing the list of SSIDs to scan.
    * `<bssid_output_file>`: The file where BSSIDs and channels will be saved.
    * `<interface>`: The wireless interface to use for scanning (e.g., `wlan0mon`).

### 2. `monitor_bssids.sh`

- **Description:** This Bash script monitors the BSSIDs obtained from the `get_bssids.py` script. It logs the results and outputs signal strength information.
- **Usage:**
  ```bash
  bash monitor_bssids.sh <interface>
  ```
  * Arguments
    * `<interface>`: The wireless interface to use for scanning (e.g., `wlan0mon`).

### 3. `automate_monitoring.sh`

- **Description:** This wrapper script automate the process by first running the `get_bssids.py` script to retrive BSSIDs and then running `monitor_bssids.sh` to monitor those BSSIDs. It handles the setup of the wireless interface and ensures `NetworkManager` is restarted afterward.
- **Usage:**
  ```bash
  bash automate_monitoring.sh <interface>
  ```
  * Process
    * Finds a suitable wireless interface and puts it into monitor mode.
    * Runs the `get_bssids.py` script to retrive BSSIDs and channels.
    * Runs the `monitor_bssids.sh` script to monitor the BSSIDs.
    * Restarts `NetworkManager` after monitoring is complete.

## Systemd Setup
To run the `automate_monitoring.sh` script automatically at boot using `systemd`, follow these steps:

### 1. Create a Systemd Service File
Create a service file in `/etc/systemd/system/` directory

```bash
sudo nano /etc/systemd/system/wifi-monitor.service
```

### 2. Add the following Content to the Service File

```ini
[Unit]
Description=Wireless BSSID Monitoring

[Service]
Type=simple
ExecStart=/path/to/automate_monitoring.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 3. Enable the service
To enable the service so that it runs at boot, use the following command:

```bash
sudo systemctl enable wifi-monitor.service
```

### 4. Start the service

You can start the service immediately with:

```bash
sudo systemctl start wifi-monitor.service
```

### 5. Check the status of the service
To verify that service is running correctly, check its status:

```bash
sudo systemctl status wifi-monitor.service
```

## Notes:
* Interface Setup: The scripts handle setting the wireless interface to monitor mode and ensuring `NetworkManager` is restarted afterward to restore network connectivity.
* Lock File: The `automate_monitoring.sh` script uses a lock file to prevent multiple instances from running simultaneously.

## Troubleshooting
* Interface Not Found: Ensure your wireless adapter supports monitor mode. If `airmon-ng` fails to set the interface to monitor mode, the script will log an error and exit.
* Network Connectivity: Running `airmon-ng check kill` disables network services that may interfere with monitor mode. The script restarts `NetworkManager` after monitoring is complete.