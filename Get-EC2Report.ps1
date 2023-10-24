$ReportFile = ("~\Documents\" + (Get-Date -Format "yyyyMMdd-HHmm") + "-EC2-Report.txt")
if (-not (Test-Path $ReportFile)) {
  Set-Content -Path $ReportFile -Value "Instance ID`tName`tAvailability Zone`tStatus`tInstance Type"
  $REGIONLIST = aws ec2 describe-regions --query Regions[*].[RegionName] --output text
  foreach ($REGION in $REGIONLIST) {
	  $OUTPUT = aws ec2 describe-instances --region $REGION --output text --query "Reservations[].Instances[].{Name: Tags[?Key == 'Name'].Value | [0], Region:Placement.AvailabilityZone, Id: InstanceId, State: State.Name, Type: InstanceType}"
	  Add-Content -Path $ReportFile -Value $OUTPUT
  }
  Write-Host "Report saved to the file $ReportFile"
} else {
throw "File already exists and will not be overwritten. Wait 60 seconds and run again: $ReportFile"
}
