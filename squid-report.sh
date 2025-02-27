#!/bin/bash

# Assumes a modified squid log format
# logformat timestamp %tl{%Y-%m-%d %H:%M:%S}.%03tu %tl{%z} %6tr %>a %Ss/%03>Hs %<st %rm %ru %un %Sh/%<A %mt

# Path to the Squid access log
LOG_FILE="/var/log/squid/access.log"

# Get the date for the previous day in the desired format
previous_day=$(date -d "yesterday" +"%Y-%m-%d")

# Output file for the report
OUTPUT_FILE="squid_report-$previous_day.txt"

# Check if the log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Log file not found!"
    exit 1
fi

# Process the log file and generate the report for the previous day
echo "Generating report for Squid access logs for $previous_day..."
echo "Destination Summary Report" > "$OUTPUT_FILE"
echo "=========================" >> "$OUTPUT_FILE"
echo "Destination       Requests       Data Transferred (GB)" >> "$OUTPUT_FILE"
echo "--------------------------------------------------------" >> "$OUTPUT_FILE"

# Use awk to summarize data based on the new log format and filter by date
awk -v prev_date="$previous_day" '{
    # Extract the date part from the timestamp
    log_date = substr($1, 1, 10);  # Assuming $1 has the format YYYY-MM-DD
    if (log_date == prev_date && $10 != "CONNECT") {  # Filter by date and request type
        dest[$9]++;                 # Count requests for each destination (requested URL in field 9)
        data[$9] += $7;            # Sum the data transferred (response size in field 7)
    }
} END {
    for (d in dest) {
        data_in_gb = data[d] / (1024 * 1024 * 1024);  # Convert bytes to GB
        printf "%-16s %-10d %.2f\n", d, dest[d], data_in_gb;
    }
}' "$LOG_FILE" | sort >> "$OUTPUT_FILE"

# Display the report
cat "$OUTPUT_FILE"

echo "Report generated: $OUTPUT_FILE"
