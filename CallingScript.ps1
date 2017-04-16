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

$URI       = 'https://raw.githubusercontent.com/ShayaanF/mentorproject/master/'
$VNETTemplate = 'vnetdeploy.json'
$ADTemplate = 'activedirectorydeploy.json'
$VMTemplate = 'vmdeploy.json'
$SQLTemplate = 'sqldeploy.json'
$JoinTemplate = 'joinvm.json'

$Location  = 'east us'

#---------- Resource Groups  ----------
$vnetrgname    = 'ShyMentoringPrj-VNET'
$adclrgname    = 'ShyMentoringPrj-AD'
$apprgname    = 'ShyMentoringPrj-APP'
$dbrgname    = 'ShyMentoringPrj-DB'


#---------- Storage Accounts (lowercase only)  ----------
$StorageAccountAD = 'shyadstorage'
$StorageAccountAPP = 'shyappstorage'
$StorageAccountDB1 = 'shydbstorage1'
$StorageAccountDB2 = 'shydbstorage2'
$StorageAccountDB3 = 'shydbstorage3'

#---------- Authenticate/Select Subscription ----------
Login-AzureRmAccount -SubscriptionName $subscriptionName

#---------- DNS Name Check ----------
if (Test-AzureRmDnsAvailability -DomainNameLabel $addnsName -Location $Location)
{ 'Name is available, proceeding...' } else { 'Taken. addnsName must be globally unique.' }

#---------- Build Resource Groups ----------
New-AzureRmResourceGroup -Name $vnetrgname -Location $Location
New-AzureRmResourceGroup -Name $adrgname -Location $Location
New-AzureRmResourceGroup -Name $apprgname -Location $Location
New-AzureRmResourceGroup -Name $dbrgname -Location $Location

#----------------------------------------------------------------------------------------------------
#---------- VNET Template Parameters ----------
$SplatParams = @{
    TemplateUri             = $URI + $VNETTemplate
    ResourceGroupName       = $vnetrgname
   }
   

New-AzureRmResourceGroupDeployment @SplatParams -Verbose #deploy VNET and Subnets

#----------------------------------------------------------------------------------------------------
#---------- AD Template Parameters ----------
$MyParams = @{
    virtualNetworkResourceGroup = $vnetrgname
    virtualNetworkName = 'MentorVNET'
    adSubnetName = 'ADSubnet'
    adSubnet = '10.0.1.0/24'
    adNicIPAddress = '10.0.1.4'
    newStorageAccountName = $StorageAccountAD
    location              = 'East US'
    domainName            = 'shymentoring.local'
    addnsName             = 'shymentoringad' 
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

#----------------------------------------------------------------------------------------------------
#---------- VM Template Parameters ----------
$MyParams = @{
    virtualNetworkResourceGroup = $vnetrgname
    virtualNetworkName = 'MentorVNET'
    SubnetName = 'APPSubnet'
    VM01Name = 'VM01'
    VM02Name = 'VM02'
    VM01PIPDnsName = 'shymentoringvm01'
    VM02PIPDnsName = 'shymentoringvm02'

    newStorageAccountName = $StorageAccountAPP
    location              = 'East US'
   }

#--------------------------------------------
#----------------- VM Setup ----------------- 
#--------------------------------------------
$SplatParams = @{
    TemplateUri             = $URI + $VMTemplate
    ResourceGroupName       = $apprgname
    TemplateParameterObject = $MyParams
    Name                    = 'ShyMentoring'
   }


# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose


#----------------------------------------------------------------------------------------------------
#---------- Domain Join Parameters ----------
$MyParams = @{
    vmList = 'VM01,VM02'
    location              = 'East US'
    domainJoinUserName = 'ADAdministrator'
    domainFQDN = 'shymentoring.local'
   }

$SplatParams = @{
    TemplateUri             = $URI + $JoinTemplate
    ResourceGroupName       = $adrgname
    TemplateParameterObject = $MyParams
    Name                    = 'ShyMentoring'
   }


# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose


# Login as:  shymentoring\adadministrator
# Use the password you supplied at the beginning of the build.
