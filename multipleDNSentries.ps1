$ip = 1..99
 
foreach ($i in $ip) {
 
If ($i -lt 50) {
 
Add-DnsServerResourceRecord `
-ZoneName 'skydc01.com' `
-Name Web01$i -IPv4Address 192.168.2.$i -A -Verbose
 
}
else
{
Add-DnsServerResourceRecord `
-ZoneName 'test.local' `
-Name Web01$i -IPv4Address 192.168.2.$i -A -Verbose
}
}