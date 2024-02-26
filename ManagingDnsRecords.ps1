###########Promoting Server as a Domain Controller#############


get-windowsfeature | Format-Table
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

#Install module for AD deployment 
Import-Module ADDSDeployment

#Configure and promote server as AD
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "skydc01.com" `
-DomainNetbiosName "SKYDC010" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

#Restart-Computer -ComputerName skydc01

#Add reverse lookup ptr domain "Note reverse lookup is not configured by default if during install ad features you don't add -Include managementtools 
Add-DnsServerPrimaryZone -ComputerName skydc01 -NetworkId "192.168.1.0/24" -ReplicationScope Forest


Get-ADDomainController

#Managing DNS Resources Records

Get-DnsServerResourceRecord -ZoneName skydc01.com -RRType A

Get-DnsServerResourceRecord -ZoneName skydc01.com -RRType A | Where HostName -NE "@"

#TTL recursive server or local resolver how long it should keep said record in its cache, in this case greater than 15mins
Get-DnsServerResourceRecord -ZoneName skydc01.com -RRType A | Where TimeToLive -GE "00:15:00"

#Where record of the host computer is not equal to parent record.
Get-DnsServerResourceRecord -Computername skydc01 -ZoneName skydc01.com -RRType A | Where HostName -NE "@"


#A & AAAA records addition

#Add-DnsServerResourceRecordA -Name "webapp02" -ZoneName "sykdc01.com" -IPv4Address 192.138.1.6   -command failed with error "Zone not found"

Add-DnsServerResourceRecordA -Name "WebApp02" -ZoneName "skydc01.com" -AllowUpdateAny -IPv4Address "192.168.1.9" -TimeToLive 08:00:00
Remove-DnsServerResourceRecord -ZoneName "skydc01.com" -Name "WebApp01" -RRType A


#PTR Records additon


#Configure DNS Reverse pointer zone 
Add-DnsServerResourceRecordPtr -Name "4" -PtrDomainName "skydc01.com" -ZoneName "1.168.192.in-addr.arpa" -ComputerName skydc01

Add-DnsServerResourceRecordPtr -Name "8" -PtrDomainName "WepApp01.skydc01.com" -ZoneName "1.168.192.in-addr.arpa" -ComputerName skydc01

#Check dns configured zone
Get-DnsServerResourceRecord -ComputerName skydc01 -ZoneName "1.168.192.in-addr.arpa"


#CNAME
Add-DnsServerResourceRecordCName -ZoneName skydc01.com -HostNameAlias "WebApp01.skydc01.com" -Name "Accountanting"

#Check CNAME creation
Get-DnsServerResourceRecord -ZoneName skydc01.com -RRType CName

#SRV Records
Register-DnsClient
Restart-Service -Name Netlogon

#Verify Netlogon services has started.
Get-service -Name Netlogon

#Zone Types 

#Get list of zones
Get-DnsServerZone
#Zone Types

#Get list of zones
Get-DnsServer -ComputerName skydc02.skydc01.com

#Rerverse DNS zone Server not listed
Get-DnsServerZone | Where IsReverseLookupZone -EQ $true

#Lookup Dns server that AD intergrated.
Get-DnsServerZone|where IsDsIntegrated -eq false | Format-Table -AutoSize 

#Create AD Integrated zone
Add-DnsServerPrimaryZone -Name "edwinamoo.org" -ReplicationScope Forest

#Transfer zone 
Start-DnsServerZoneTransfer -Name "edwinamoo.org" -ComputerName skydc01 -FullTransfer

#Create Reverse lookup
Add-DnsServerPrimaryZone -ComputerName skydc01 -NetworkId "192.168.1.4" -ReplicationScope Forest

Add-DnsServerStubZone -Name "google.com" -MasterServers "192.168.1.4" -PassThru -ZoneFile ".dns"

#setting zone aging and scavanging
Get-DnsServerZoneAging -Name edwinamoo.org

Set-DnsServerZoneAging -Name edwinamoo.org -Aging $true -RefreshInterval 3.00:00:00 -NoRefreshInterval 3.00:00:00


#Cache Locking
Get-DnsServerCache

Set-DnsServerCache -LockingPercent 80

#DNS SERCURITY - https://www.globalknowledge.com/us-en/resources/resource-library/articles/optimizing-dns-for-better-performance-filtering-and-security/#gref
#Enhancing DNS https://cleanbrowsing.org/filters -Adult content filtering
#CleanBrowsing (https://cleanbrowsing.org/filters): Security filter:
#DNSSEC ensures that communications between DNS servers is verified using mutual certificate authentication and is then protected inside a TLS encrypted communications tunnel. 
#Design Deployment chrome-extension://efaidnbmnnnibpcajpcglclefindmkaj/https://bluecatnetworks.com/wp-content/uploads/2020/06/DNS-Infrastructure-Deployment.pdf
