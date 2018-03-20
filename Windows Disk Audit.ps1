# Set-ExecutionPolicy Unrestricted -Force
Set-ExecutionPolicy Unrestricted -Force

#delete reports older than 7 days
$OldReports = (Get-Date).AddDays(-7)

#edit the line below to the location you store your disk reports# It might also
#be stored on a local file system for example, D:\ServerStorageReport\DiskReport
Get-ChildItem C:\Scripts\DiskReports\*.* | `
Where-Object { $_.LastWriteTime -le $OldReports} | `
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue  

#Create variable for log date
$LogDate = get-date -f yyyyMMdd

#Pulls servers from Active Directory using wildcard Server*.  You could also point to OU
$DiskReport = ForEach ( $Servernames in ((dsquery computer "DC=YourDC,DC=local" -name Server* -o rdn -limit 0).Replace("`"",""))) 

{Get-WmiObject win32_logicaldisk <#-Credential $RunAccount#> `
-ComputerName $Servernames -Filter "Drivetype=3" `
-ErrorAction SilentlyContinue | 

#return only disks with
#free space less  
#than or equal to 0.1 (10%).  I set it to 1.0 to just show all disk however you could change the below from 1.0 to .1 to only show servers with 10%.  

Where-Object {   ($_.freespace/$_.size) -le '1.0'}

} 


#create reports
$DiskReport | 

Select-Object @{Label = "Server Name";Expression = {$_.SystemName}},
@{Label = "Drive Letter";Expression = {$_.DeviceID}},
@{Label = "Total Capacity (GB)";Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
@{Label = "Free Space (GB)";Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) }},
@{Label = 'Free Space (%)'; Expression = {"{0:P0}" -f ($_.freespace/$_.size)}},
@{Label = 'Used Space (GB)'; Expression = {"{0:N1}" -f (($_.Size - $_.FreeSpace) / 1gb)}} |

#Export report to CSV file (Disk Report)
Export-Csv -path "C:\Scripts\DiskReports\VM_DiskReport_$logDate.csv" -NoTypeInformation

# Attach and send CSV report (Most recent report will be attached)
Send-MailMessage -SmtpServer smtp.yourserver.net -To "name1@company.com.com", "name2@company.com.com", "name3@company.com.com" -From "DCCDiskReport@catalent.com" -Subject "DCC Monthly Server Storage Report" -Attachments "C:\Scripts\DiskReports\VM_DiskReport_DiskReport_$logDate.csv"    