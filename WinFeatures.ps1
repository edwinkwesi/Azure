#ActiveDirectory deployment ##########
get-windowsfeature | Format-Table
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

Restart-Computer -ComputerName skydc01

Get-ADDomainController

get-windowsfeature | Format-Table

#Get-Command -Module ADDSDeployment

#Promt user to enter password for safemode access
#$Password = Read-Host -Prompt   'Enter SafeMode Admin Password' -AsSecureString

#Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath C:\Windows\NTDS -DomainMode WinThreshold -DomainName skydc02.lab -DomainNetbiosName SKYDC02 -ForestMode WinThreshold -InstallDns:$true -LogPath C:\Windows\NTDS -NoRebootOnCompletion:$true -SafeModeAdministratorPassword $Password -SysvolPath C:\Windows\SYSVOL -Force:$true

######DNS deployment

#Install-WindowsFeature -Name DNS



Add-DnsServerForwarder -IPAddress "<IpAddressHere>"

#Confirm the forwarder was added
Get-DnsServerForwarder

#Get-NetIPAddress | fl IPAddress,InterfaceAlias

#check reverse zones
Get-DnsServerZone

Add-DnsServerPrimaryZone -NetworkID “NetworkIDHere” -ReplicationScope “ReplciationScopeHere"
Get-DnsServerZone 