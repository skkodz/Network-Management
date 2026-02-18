#!/bin/bash
# Script to check and alert on disk space usage, if it goes above a threshold
# The threshold defaults to 90% and will output a warning if the disk space is
# greater or equal to the threshold, unless it was previously recorded (in the
# STATE_FILE) as that value, of the figure drops below the threshoold when
# previously above it (recovery).
# Ideal for using in a cron job, e.g. to run every 5 minutes:
# */5 * * * * /usr/local/bin/check_disk_space.sh

# --- Defaults ---
THRESHOLD=90
STATE_FILE="/tmp/disk_usage_state.txt"
SYSTEM_NAME=$(hostname)

# --- Parse Arguments ---
while getopts "t:f:" opt; do
  case $opt in
    t) THRESHOLD=$OPTARG ;;
    f) STATE_FILE=$OPTARG ;;
    *) echo "Usage: $0 [-t threshold] [-f state_file]"; exit 1 ;;
  esac
done

# --- 1. Validate Threshold ---
# Check if THRESHOLD is a positive integer
if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: Threshold '$THRESHOLD' is not a valid integer." >&2
    exit 1
fi

# --- 2. Validate State File Path ---
# Get the directory path of the state file
STATE_DIR=$(dirname "$STATE_FILE")

# Check if directory exists
if [ ! -d "$STATE_DIR" ]; then
    echo "Error: Directory '$STATE_DIR' does not exist." >&2
    exit 1
fi

# Check if directory is writable (to create/update the file)
if [ ! -w "$STATE_DIR" ]; then
    echo "Error: Directory '$STATE_DIR' is not writable." >&2
    exit 1
fi

# If the file already exists, check if it's writable
if [ -f "$STATE_FILE" ] && [ ! -w "$STATE_FILE" ]; then
    echo "Error: State file '$STATE_FILE' exists but is not writable." >&2
    exit 1
fi

# Ensure file exists for the rest of the script
touch "$STATE_FILE"

# Process ALL physical disks
df -h --output=pcent,target -x squashfs -x tmpfs -x devtmpfs | tail -n +2 | while read -r line; do
    usage=$(echo "$line" | awk '{print $1}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $2}')

    # Extract the previous percentage for THIS mountpoint
    prev_usage=$(grep "^$mount " "$STATE_FILE" | awk '{print $2}')

    # CASE 1: The disk is currently over the threshold
    if [ "$usage" -ge "$THRESHOLD" ]; then
        # Alert if it's the first time hitting 90, OR if the number changed
        if [ -z "$prev_usage" ] || [ "$usage" != "$prev_usage" ]; then
            echo "ALERT: $mount on $SYSTEM_NAME is at ${usage}% (Was: ${prev_usage:-<90}% )"
        fi

    # CASE 2: The disk was over 90, but now it is under (Recovery)
    elif [ -n "$prev_usage" ] && [ "$prev_usage" -ge "$THRESHOLD" ] && [ "$usage" -lt "$THRESHOLD" ]; then
        echo "CLEARED: $mount on $SYSTEM_NAME has dropped to ${usage}% (Was: ${prev_usage}%)"
    fi

    # ALWAYS update the state file with the current percentage for every drive
    # This keeps the file a "live" mirror of the system
    sed -i "\|^$mount |d" "$STATE_FILE"
    echo "$mount $usage" >> "$STATE_FILE"
done
