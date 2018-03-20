##Script connects to a single or multiple VCenters, Creates a CSV file, removes old files less than 7 Days old, and emails the CSV file.  CSV File includes Server Name, Disk Name, Capacity, Free Space GB, Percent Free, & Used Space GB

#delete reports older than 7 days
$OldReports = (Get-Date).AddDays(-7)

#edit the line below to the location you store your disk reports
# It might also be stored on a local file system for example, D:\ServerStorageReport\DiskReport

Get-ChildItem C:\Scripts\DiskReports\*.* | `
Where-Object { $_.LastWriteTime -le $OldReports} | `
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue  

#Create variable for log date
$LogDate = get-date -f yyyyMMdd

## Load PowerCLI Powershell Snapin
    #Prevent loading Snapin if already loaded
    if (([bool](Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) -eq $false)
    {
        Write-Verbose "Loading VMware PowerCLI Plugin"
        Import-Module VMware.VimAutomation.Core
        Write-Verbose "Loading VMware PowerCLI Plugin Complete"
    }
    else
    {
        Write-Verbose "VMware PowerCLI Plugin already loaded"
    }
## CONNECT TO FIRST VCENTER.  Add your VCenter Server name
Connect-VIServer -Server VCENTERSERVER_NAME_HERE | Out-Null
$VMs = Get-VM

$Report = @()
ForEach ($VM in $VMs)
{
($row = $VM.Extensiondata.Guest.Disk | Select @{N="Name";E={$VM.Name}},DiskPath, @{N="Capacity(GB)";E={[math]::Round($_.Capacity/ 1GB)}}, @{N="Free Space(GB)";E={[math]::Round($_.FreeSpace / 1GB)}}, @{N="Percent Free";E={[math]::Round(($_.FreeSpace / $_.Capacity) * 100)}}, @{N="Used Space (GB)";E={[math]::Round(($_.Capacity - $_.FreeSpace) / 1GB)}})
    $Report += $row
}

$Report | Export-Csv "C:\Scripts\DiskReports\Vcenter1_VM-Guest_Size_$logDate.csv" -NoTypeInformation

## CONNECT TO SECOND VCENTER. Add your VCenter Server Name  Remove this section if you only need one VCenter.  Copy this section to add more VCenter Servers.  
Connect-VIServer -Server VCENTERSERVER_NAME_HER | Out-Null
$VMs = Get-VM

$Report = @()
ForEach ($VM in $VMs)
{
($row = $VM.Extensiondata.Guest.Disk | Select @{N="Name";E={$VM.Name}},DiskPath, @{N="Capacity(GB)";E={[math]::Round($_.Capacity/ 1GB)}}, @{N="Free Space(GB)";E={[math]::Round($_.FreeSpace / 1GB)}}, @{N="Percent Free";E={[math]::Round(($_.FreeSpace / $_.Capacity) * 100)}}, @{N="Used Space (GB)";E={[math]::Round(($_.Capacity - $_.FreeSpace) / 1GB)}})
    $Report += $row
}

$Report | Export-Csv "C:\Scripts\DiskReports\VCenter2_VM-Guest_Size_$logDate.csv" -NoTypeInformation

#Send Attachments to Recipients.  The script shows multiple email addresses to email out and is emailing multiple files. You will need to update your SMTP Server.   
Send-MailMessage -SmtpServer smtp.server.net -To "name1@company.com", "name2@company.com", "name3@company.com" -From "DiskReport@company.com" -Subject "VM Monthly Server Storage Reports" -Attachments "C:\Scripts\DiskReports\VCenter1_VM-Guest_Size_$logDate.csv", "C:\Scripts\DiskReports\VCenter2_VM-Guest_Size_$logDate.csv"            
