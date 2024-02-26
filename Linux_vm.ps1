New-AzResourceGroup -Name vmrg -Location uksouth

#Create credentials and assign it to unix box from user input from user input.
$cred = Get-Credential

## Create IP. ##
$ip = @{
    Name = 'vmPublicIP'
    ResourceGroupName = "vmrg"
    Location = "uksouth"
    Sku = 'Standard'
    AllocationMethod = 'Static'
    IpAddressVersion = 'IPv4'
}
New-AzPublicIpAddress @ip

## Create virtual machine. ##
New-AzVm `
    -ResourceGroupName 'vmrg' `
    -Name 'vmps1' `
    -Location 'uksouth' `
    -image Debian11 `
    -size Standard_B2s `
    -PublicIpAddressName vmPublicIP `
    -OpenPorts 80 `
    -GenerateSshKey `
    -SshKeyName mySSHKey