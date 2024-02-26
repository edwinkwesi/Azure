Install-Module -Name Az -Repository PSGallery -Force

$ResourceGroupName = "vmrg"
$Location = "uksouth"
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

#Create sql network settings

$SubnetName = $ResourceGroupName + "sqlnet"
$VnetName = $ResourceGroupName + "sql-vnet"
$PipName = $ResourceGroupName + "sql-public-ip"

# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 192.168.1.0/24

# Create a virtual network
$Vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VnetName -AddressPrefix 192.168.0.0/16 -Subnet $SubnetConfig

# Create a public IP address and specify a DNS name
$Pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $PipName

#Create a network security group. Configure rules to allow remote desktop (RDP) and SQL Server connections.

# Rule to allow remote desktop (RDP)
$NsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp `
   -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

#Rule to allow SQL Server connections on port 1433
$NsgRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp `
   -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow

# Create the network security group
$NsgName = $ResourceGroupName + "nsg"
$Nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
    -Location $Location -Name $NsgName `
    -SecurityRules $NsgRuleRDP,$NsgRuleSQL

#Create the network interface.
$InterfaceName = $ResourceGroupName + "int"
$Interface = New-AzNetworkInterface -Name $InterfaceName `
    -ResourceGroupName $ResourceGroupName -Location $Location `
    -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $Pip.Id `
    -NetworkSecurityGroupId $Nsg.Id

# Define a credential object
$SecurePassword = ConvertTo-SecureString 'Adwoaasi1' `
    -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("sqladmin", $securePassword)

# Create a virtual machine configuration
$VMName = $ResourceGroupName + "VM"
$VMConfig = New-AzVMConfig -VMName $VMName -VMSize Standard_DS13_V2 |
    Set-AzVMOperatingSystem -Windows -ComputerName $VMName -Credential $Cred -ProvisionVMAgent -EnableAutoUpdate |
    Set-AzVMSourceImage -PublisherName "MicrosoftSQLServer" -Offer "SQL2017-WS2016" -Skus "SQLDEV" -Version "latest" |
    Add-AzVMNetworkInterface -Id $Interface.Id

# Create the VM
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMConfig