# Network-Management
Some basic scripts written to perform useful functions when managing a computer network or environment.

## GetEC2Report.ps1
Uses [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) to enumerate all EC2 instances across all AWS regions. Generates a text file report containing the Instance ID, Name Availability Zone Status and INstance Type.

## Get-TreeSize.ps1
Basic PowerShell script to display the size of a directory tree in GB.

## test-down
Basic shell script that will notify on screen (and sound the default bell) when a given IP address stops responding to ICMP traffic (ping).

## test-up
Basic shell script that will notify on screen (and sound the default bell) when a given IP address starts responding to ICMP traffic (ping).

test-down and test-up can be used to check that a device reboots. By running in a shell:
``` sh
test-down 192.168.0.1 && test-up 192.168.0.1
```
You should hear two bells to confirm the device has gone down and two more when it comes back up again. Useful to run in a shell that you do not need to visually monitor, but still know once the device has rebooted.
