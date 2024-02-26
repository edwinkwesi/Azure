# Create variables to store the location and resource group names.
$location = "uksouth"
$ResourceGroupName = "DC-RG"

New-AzResourceGroup `
    -Name $ResourceGroupName `
    -Location $location


# Create variables to store the storage account name and the storage account SKU information
$StorageAccountName = "dcstgacc"
$SkuName = "Standard_LRS"

# Create a new storage account
#$StorageAccount = New-AzStorageAccount `
#    -Location $location `
#    -ResourceGroupName $ResourceGroupName `
#    -Type $SkuName `
#    -Name $StorageAccountName

#https://learn.microsoft.com/en-us/rest/api/storagerp/srp_sku_types  Refeference to the SKU tyyes

New-AzStorageAccount -Location $location -ResourceGroupName $ResourceGroupName -Type $SkuName -Name $StorageAccountName


Set-AzCurrentStorageAccount `
    -StorageAccountName $storageAccountName `
    -ResourceGroupName $resourceGroupName


# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name skydc01stgaccSubnet `
    -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location $location `
    -Name MyVnet `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Location $location `
    -AllocationMethod Static `
    -IdleTimeoutInMinutes 4 `
    -Name "skydc01PubDns"

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
    -Name skydc01NetSGRDP `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix 185.237.62.101 `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
    -Name skydc01NetSGRWWW `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80 `
    -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Location $location `
    -Name skydc01NetSG `
    -SecurityRules $nsgRuleRDP,$nsgRuleWeb

# Create a virtual network card and associate it with public IP address and NSG
$nic = New-AzNetworkInterface `
    -Name SKYDC01Nic `
    -ResourceGroupName $ResourceGroupName `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id `
    -NetworkSecurityGroupId $nsg.Id


# Define a credential object to store the username and password for the VM
$UserName='eamoo'
$Password='Adwoaasi1234'| ConvertTo-SecureString -Force -AsPlainText
$Credential=New-Object PSCredential($UserName,$Password)

# Create the VM configuration object
$VmName = "skydc01"
$VmSize = "Standard_D2"
$VirtualMachine = New-AzVMConfig `
    -VMName $VmName `
    -VMSize $VmSize

$VirtualMachine = Set-AzVMOperatingSystem `
    -VM $VirtualMachine `
    -Windows `
    -ComputerName "skydc01" `
    -Credential $Credential -ProvisionVMAgent

$VirtualMachine = Set-AzVMSourceImage `
    -VM $VirtualMachine `
    -PublisherName "MicrosoftWindowsServer" `
    -Offer "WindowsServer" `
    -Skus "2019-Datacenter" `
    -Version "latest"

# Sets the operating system disk properties on a VM.
$VirtualMachine = Set-AzVMOSDisk `
    -VM $VirtualMachine `
    -CreateOption FromImage | `
    Set-AzVMBootDiagnostic -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName -Enable |`
    Add-AzVMNetworkInterface -Id $nic.Id

# Create the VM.
New-AzVM `
    -ResourceGroupName $ResourceGroupName `
    -Location $location `
    -VM $VirtualMachine