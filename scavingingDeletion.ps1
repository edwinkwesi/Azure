$IPRange = '192.168.1.*'
$ZoneName = 'asidc01.com'
$DNSQueryDC = 'asidc01.com'

# Get DNS records - exclude what you can here as "Group-Object" is slow - it will make subsequent processing faster
$RecordsDC =  Get-DnsServerResourceRecord -ComputerName $DNSQueryDC -ZoneName $ZoneName -RRType A | Where-Object {
    ($_.Timestamp)`
    -and ($_.HostName -notlike "*$ZoneName*")`
    -and ($_.HostName -ne '@')
}

# Get all records matching the IP range
$CollectionDC = $RecordsDC | Where-Object { $_.RecordData.IPv4Address -like $IPRange } | ForEach-Object {
[pscustomobject] @{RecordName = $_.HostName;IP = $_.RecordData.IPv4Address;Timestamp = $_.TimeStamp}    
}

# Group by IP to retrieve duplicates
$CollectionDC | Group-Object -Property IP | Where-Object { $_.Count -gt 1} | ForEach-Object {
    # Sort by timestamp, then select all except the most recent one
    Write-Host "Found duplicate IPs for: " $_.Name -ForegroundColor Yellow
    $DuplicateIPs = $_.Group | Sort-Object Timestamp -Descending
    Write-Host "`nMost recent record:" 
    $DuplicateIPs | Select-Object -First 1 | Out-Host

    $RecordsToDelete = $DuplicateIPs | Select-Object -Skip 1
    Write-Host "Deleting older records:" -ForegroundColor Cyan
    $RecordsToDelete | Out-Host
    # Now remove them
    #
}

$LatestRecord = @()
foreach($Record in $TotalDuplicateIP | Group-Object IP | Sort-Object Timestamp)
{
    $LatestRecord += $Record.Group | select -Last 1
}

$Filtered = $TotalDuplicateIP | Where-Object { $_ -notin $LatestRecord }

foreach($ToRemoveItem in $Filtered)
{
    #Write-Host -ForegroundColor Green "Removing:" $ToRemoveItem.Timestamp $ToRemoveItem.IP $ToRemoveItem.RecordName
    Remove-DnsServerResourceRecord -ZoneName "blaaaa.com" -RRType A -Name $ToRemoveItem.RecordName -RecordData $ToRemoveItem.IP -WhatIf
}
