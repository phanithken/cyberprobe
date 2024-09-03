import subprocess
import time
import os
import sys

def get_bssid(ssid_list_file, output_file, interface, scan_time=10):
    script_dir = os.path.dirname(os.path.realpath(__file__))
    ssid_list_path = os.path.join(script_dir, ssid_list_file)
    output_file_path = os.path.join(script_dir, output_file)

    # Read the SSIDs from the provided file
    with open(ssid_list_path, 'r') as file:
        ssids = [line.strip() for line in file.readlines()]

    bssid_dict = {}

    try:
        for ssid in ssids:
            print(f"Scanning for SSID: {ssid} using interface {interface}")
            command = [
                "sudo", "airodump-ng", "--essid", ssid, "--write", "scan_output", "--output-format", "csv", interface
            ]
            subprocess.Popen(command)
            time.sleep(scan_time)
            subprocess.call(["sudo", "pkill", "airodump-ng"])  # Stop airodump-ng after the scan

            # Parse the csv output to find the BSSID
            scan_output_file = 'scan_output-01.csv'
            with open(scan_output_file, 'r') as csv_file:
                lines = csv_file.readlines()

            for line in lines:
                if ssid in line:
                    bssid = line.split(',')[0].strip()
                    channel = line.split(',')[3].strip()
                    bssid_dict[ssid] = {"bssid": bssid, "channel": channel}
                    print(f"Found BSSID for {ssid}: {bssid} on Channel: {channel}")
                    break
            else:
                print(f"BSSID for SSID {ssid} not found.")

            # Cleanup scan files
            subprocess.call(["rm", scan_output_file])

    except KeyboardInterrupt:
        print("\nProcess interrupted by user.")

    # Save BSSIDs to the output file
    with open(output_file_path, 'w') as outfile:
        for ssid, info in bssid_dict.items():
            outfile.write(f"{ssid}: {info['bssid']}, Channel: {info['channel']}\n")

    print(f"\nBSSIDs and channels saved to {output_file_path}")

    return bssid_dict

if __name__ == "__main__":
    ssid_list_file = sys.argv[1]
    output_file = sys.argv[2]
    interface = sys.argv[3]

    bssids = get_bssid(ssid_list_file, output_file, interface)
    print("\nSummary of BSSIDs and Channels:")
    for ssid, info in bssids.items():
        print(f"SSID: {ssid}, BSSID: {info['bssid']}, Channel: {info['channel']}")
