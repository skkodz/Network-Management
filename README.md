# Network-Management
Some basic scripts written to perform useful functions when managing a computer network or environment.

## Get-ADUserReport.ps1
Creates a CSV export from your local active directory that can be imported into Excel. Useful for getting a quick overview of user account information for your entire domain.

## Get-EC2Report.ps1
Uses [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) to enumerate all EC2 instances across all AWS regions. Generates a text file report containing the *Instance ID*, *Name*, *Availability Zone*, *Status* and *Instance Type*.  Automatically creates a time stamped text file report in the directory ~\Documents.

## Get-TreeSize.ps1
Basic PowerShell script to display the size of a directory tree in GB. Accepts the optional parameter *-path*, otherwise defaults to the current directory.

## test-down
Basic shell script that will notify on screen (and sound the default bell) when a given IP address stops responding to ICMP traffic (ping). Expects a valid IP address as the only mandatory parameter, othrewise throws an error.

## test-up
Basic shell script that will notify on screen (and sound the default bell) when a given IP address starts responding to ICMP traffic (ping). Expects a valid IP address as the only mandatory parameter, othrewise throws an error.

test-down and test-up can be used to check that a device reboots. By running in a shell:
``` sh
test-down 192.168.0.1 && test-up 192.168.0.1
```
You should hear two bells to confirm the device has gone down and two more when it comes back up again. Useful to run in a shell that you do not need to visually monitor, but still know once the device has rebooted.
