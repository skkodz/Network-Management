#!/usr/bin/bash

# Script to check the SFTP log file for any files written
# within the previous 10 minute period.
# This script is designed to be run as a scheduled task
# Every ten minutes like 1-59/10 * * * *

# Log file to which the SFTP server is writing
SFTPLOG=/var/log/auth.log

# Variable to hold the search string based upon time
# in the format MMM hh:m
LASTTEN=$(date -d '10 minutes ago' '+%b %d %H:%M' | awk -F: '{print $1 ":" substr($2,1,1)}')

# Ths variable is the secondary search string to look for a file that has been written
SEARCH='written \b[1-9][0-9]*\b'

# Run the search and put into a string.
CONTENT=$(grep "$LASTTEN" $SFTPLOG | grep -E "$SEARCH")

if [[ -n "$CONTENT" ]]; then
  LASTTEN+="0"
  echo -e "Since $LASTTEN the following data has been uploaded to the SFTP server.\n"
  echo "$CONTENT" | awk '{printf "%s\r\n\r\n", $0}'
fi
