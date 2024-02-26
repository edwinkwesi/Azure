
$Arecord = 1..3
 
foreach ($i in $Arecord) {
 
If ($i -eq 1 +1) {
 
    Remove-DnsServerResourceRecord `
    -ZoneName "skydc01.com" `
    -RRType "A" -Name Webapp0$i -RecordData 192.168.1.$i -Verbose
 
    }
}

