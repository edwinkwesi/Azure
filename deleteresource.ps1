Install-Module -Name Az -Repository PSGallery -Force

$resource = Get-AzResourceGroup | Format-Table

write-output $resource

$inputuser = Read-host "Please enter from the list the resource group you wish to delete"

Remove-AzResourceGroup -ResourceGroupName $inputuser