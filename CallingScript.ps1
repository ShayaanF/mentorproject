$MyCurDir = $PsScriptRoot

#---------- Install needed modules ----------
#Install-Module AzureRM -Force -Verbose
#Install-AzureRM
#Install-Module Azure -Force -Verbose
#Import-AzureRM -Verbose
#Import-Module Azure -Verbose

#------------------------------------------
#---------- Variable Definitions ----------
#------------------------------------------
$subscriptionName = 'Microsoft Azure Internal Consumption'

$URI       = 'https://raw.githubusercontent.com/GoateePFE/AzureRM/master/active-directory-new-domain-with-data/azuredeploy.json'
$Location  = 'east us'
$rgname    = 'ShyMentoringPrj'

#---------- Storage Accounts (lowercase only)  ----------
$StorageAccountGeneral = 'shygeneralstorage'
$StorageAccountDB1 = 'shydbstorage1'
$StorageAccountDB2 = 'shydbstorage2'
$StorageAccountDB3 = 'shydbstorage3'

$addnsName = 'shymentoringad'     # Lowercase required

#------------------------------------------------------
#---------- Authenticate/Select Subscription ----------
#------------------------------------------------------
Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName $subscriptionName

#---------- DNS Name Check ----------
if (Test-AzureRmDnsAvailability -DomainNameLabel $addnsName -Location $Location)
{ 'Available' } else { 'Taken. addnsName must be globally unique.' }

#---------- Build Resource Group ----------
New-AzureRmResourceGroup -Name $rgname -Location $Location

#---------- AD Template Parameters ----------
$MyParams = @{
    newStorageAccountName = $StorageAccountGeneral
    location              = 'East US'
    domainName            = 'shymentoring.local'
    addnsName             = $addnsName
   }

#--------------------------------------------
#---------- Active Directory Setup ----------
#----------- (Takes ~30 Minutes) -----------
#--------------------------------------------
$SplatParams = @{
    TemplateUri             = $URI 
    ResourceGroupName       = $rgname 
    TemplateParameterObject = $MyParams
    Name                    = 'ShyMentoring'
   }


# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose

# Find the VM IP and FQDN
$PublicAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $rgname)[0]
$IP   = $PublicAddress.IpAddress
$FQDN = $PublicAddress.DnsSettings.Fqdn

# RDP either way
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$FQDN"
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$IP"

# Login as:  shymentoring\adadministrator
# Use the password you supplied at the beginning of the build.
