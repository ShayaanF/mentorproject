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

$URI       = 'https://raw.githubusercontent.com/ShayaanF/AzureRM/master/active-directory-new-domain-with-data/'
$ADTemplate = 'activedirectorydeploy.json'
$VMTemplate = 'vmdeploy.json'
$SQLTemplate = 'sqldeploy.json'
$Location  = 'east us'
$adrgname    = 'ShyMentoringPrj-AD'
$apprgname    = 'ShyMentoringPrj-APP'
$dbrgname    = 'ShyMentoringPrj-DB'


#---------- Storage Accounts (lowercase only)  ----------
$StorageAccountGeneral = 'shygeneralstorage'
$StorageAccountDB1 = 'shydbstorage1'
$StorageAccountDB2 = 'shydbstorage2'
$StorageAccountDB3 = 'shydbstorage3'

$addnsName = 'shymentoringad'     # Lowercase required

#------------------------------------------------------
#---------- Authenticate/Select Subscription ----------
#------------------------------------------------------
Login-AzureRmAccount -SubscriptionName $subscriptionName

#---------- DNS Name Check ----------
if (Test-AzureRmDnsAvailability -DomainNameLabel $addnsName -Location $Location)
{ 'Name is available, proceeding...' } else { 'Taken. addnsName must be globally unique.' }

#---------- Build Resource Groups ----------
New-AzureRmResourceGroup -Name $adrgname -Location $Location
New-AzureRmResourceGroup -Name $apprgname -Location $Location
New-AzureRmResourceGroup -Name $dbrgname -Location $Location


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
    TemplateUri             = $URI + $ADTemplate
    ResourceGroupName       = $adrgname
    TemplateParameterObject = $MyParams
    Name                    = 'ShyMentoring'
   }


# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose

# Find the VM IP and FQDN
$PublicAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $adrgname)[0]
$IP   = $PublicAddress.IpAddress
$FQDN = $PublicAddress.DnsSettings.Fqdn

# RDP either way
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$FQDN"
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$IP"

# Login as:  shymentoring\adadministrator
# Use the password you supplied at the beginning of the build.
