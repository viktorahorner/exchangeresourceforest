Add-PSSnapin *RecipientManagement
$GLOBAL:sourceforest = 'resources.onpremto.cloud'
$GLOBAL:sourcedc = 'dc2.resources.onpremto.cloud'
$GLOBAL:destinationforest = 'users.onpremto.cloud'
$GLOBAL:destinationpath = 'OU=UserAccounts,DC=User,DC=onpremto,DC=cloud'
$GLOBAL:exportlocation = 'C:\install\'
$GLOBAL:importlocation = 'C:\install\'

function Import-RemoteObjects
{
$remoteobjects = Import-Csv -Delimiter ',' -Path ($GLOBAL:importlocation+'remote-mailbox-export.csv')
$targetou = 'UserAccounts'
#RecipientTypeDetails
#RemoteEquipmentMailbox
foreach ($remotemailbox in $remoteobjects)
{
Create-NewUser -useridentity $remotemailbox.SamAccountName
    if($remotemailbox.RecipientTypeDetails -eq 'RemoteEquipmentMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -Equipment  -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
         write-host $_.ErrorDetails -ForegroundColor Magenta
        }
    }

    if($remotemailbox.RecipientTypeDetails -eq 'RemoteRoomMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -Room  -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
         write-host $_.ErrorDetails -ForegroundColor Magenta
        }
    }

    if($remotemailbox.RecipientTypeDetails -eq 'RemoteSharedMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -Shared  -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        #-ModeratedBy $remotemailbox.ModeratedBy
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
         write-host $_.ErrorDetails -ForegroundColor Magenta
        }
    }
        if($remotemailbox.RecipientTypeDetails -eq 'RemoteUserMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
         write-host $_.ErrorDetails -ForegroundColor Magenta
        }
    }

Write-Host 'Setting up additional attributes for '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
Set-RemoteMailbox -Identity $remotemailbox.UserPrincipalName -EmailAddressPolicyEnabled $false -SimpleDisplayName $remotemailbox.simpledisplayname -UserPrincipalName $remotemailbox.userprincipalname -CustomAttribute1 $remotemailbox.CustomAttribute1 -CustomAttribute2 $remotemailbox.CustomAttribute2 -CustomAttribute3 $remotemailbox.CustomAttribute3 -CustomAttribute4 $remotemailbox.CustomAttribute4 -CustomAttribute5 $remotemailbox.CustomAttribute5 -CustomAttribute6 $remotemailbox.CustomAttribute6 -CustomAttribute7 $remotemailbox.CustomAttribute7 -CustomAttribute8 $remotemailbox.CustomAttribute8 -CustomAttribute9 $remotemailbox.CustomAttribute9 -CustomAttribute10 $remotemailbox.CustomAttribute10 -CustomAttribute11 $remotemailbox.CustomAttribute11 -CustomAttribute12 $remotemailbox.CustomAttribute12 -CustomAttribute13 $remotemailbox.CustomAttribute13 -CustomAttribute14 $remotemailbox.CustomAttribute14 -CustomAttribute15 $remotemailbox.CustomAttribute15
Write-Host 'Configuration Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
Write-Host 'Adding attribute values to ADUser '
Get-ADUser -Identity $remotemailbox.SamAccountName | Set-ADUser -Replace @{ "LegacyExchangeDN" = $remotemailbox.LegacyExchangeDN} -Verbose
}
}

 function Import-ProxyAddresses
 {
 $proxylist = Import-Csv -Delimiter ',' -Path ($GLOBAL:importlocation+'proxyexport.csv')
 foreach($proxyaddress in $proxylist)
 {
    write-host 'Adding '$proxyaddress.proxyaddress' to '$proxyaddress.upn -ForegroundColor DarkGray
    Get-RemoteMailbox $proxyaddress.upn | Set-RemoteMailbox -EmailAddresses @{add=($proxyaddress.proxyaddress)} -ErrorAction SilentlyContinue
 }
 }

  function Import-ConsistancyGUID
 {
 $proxylist = @()
 $remoteobjects = Import-Csv -Delimiter ',' -Path ($GLOBAL:importlocation+'consistancyguids.csv')
 foreach($remoteobject in $remoteobjects)
 {
    Write-Host 'Exporting '$remoteobject.identity -ForegroundColor DarkGray
    $guid = Get-ADUser $remoteobject.identity  -Server resources.onpremto.cloud -Properties *
Get-ADUser $remoteobject.identity | Set-ADUser -Replace @{ "ms-Ds-ConsistencyGuid" = $guid.ObjectGUID.ToByteArray()}
Write-Host $guid.ObjectGUID.ToByteArray()' configured as ConsistencyGUID' -ForegroundColor Green
 }
 }

 function Create-NewUser
 {
  param($useridentity)
  #$useridentity = $remotemailbox.SamAccountName
  Write-Host 'Creating a new Object in Active Directory'

  $userinfo = Get-ADUser -Identity $useridentity -Properties * -Server $GLOBAL:sourceforest
    Write-Host 'Starting to create '($userinfo.name) -ForegroundColor DarkGray
    try
    {
     $newuser = New-ADUser -PassThru -Name $userinfo.Name -DisplayName $userinfo.DisplayName -UserPrincipalName $userinfo.Userprincipalname -SamAccountName $userinfo.SamAccountName  -Path $GLOBAL:destinationpath -PasswordNeverExpires $true -Enabled:$false -ErrorAction stop
     Get-ADUser $userinfo.SamAccountName | Set-ADUser -Replace @{ "ms-Ds-ConsistencyGuid" = $userinfo.ObjectGUID.ToByteArray()}
     Write-Host 'Sucessfull created '($userinfo.name) -ForegroundColor green
    }
    catch
    {
             write-host $_.ErrorDetails -ForegroundColor Magenta
    }
    try
    {
     Write-Host 'Starting to move '($userinfo.name) -ForegroundColor DarkGray
     Move-ADObject -Identity ('CN='+($userinfo.SamAccountname)+',CN=Users,DC=User,DC=onpremto,DC=cloud') -TargetPath $GLOBAL:destinationpath
     Write-Host 'Successfull moved '($userinfo.SamAccountName) -ForegroundColor green
     }
    catch
     {
      write-host $_.ErrorDetails -ForegroundColor Magenta
     }

return $newuser
 }

  function Create-NewGroup
 {
  param($useridentity)
  #$useridentity = $remotemailbox.SamAccountName
  Write-Host 'Creating a new Object in Active Directory'

  $userinfo = Get-ADGroup -Identity $useridentity -Properties * -Server $GLOBAL:sourceforest
    Write-Host 'Starting to create '($userinfo.name) -ForegroundColor DarkGray
    try
    {
     $newuser = New-ADGroup -PassThru -Name $userinfo.Name -DisplayName $userinfo.DisplayName -SamAccountName $userinfo.SamAccountName -GroupScope Universal -GroupCategory Security  -Path $GLOBAL:destinationpath -ErrorAction stop
     Get-ADGroup $userinfo.SamAccountName | Set-ADGroup -Replace @{ "ms-Ds-ConsistencyGuid" = $userinfo.ObjectGUID.ToByteArray()}
     Write-Host 'Sucessfull created '($userinfo.name) -ForegroundColor green
    }
    catch
    {
         $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
    }
    try
    {
     Write-Host 'Starting to move '($userinfo.name) -ForegroundColor DarkGray
     Move-ADObject -Identity ('CN='+($userinfo.SamAccountname)+',CN=Users,DC=User,DC=onpremto,DC=cloud') -TargetPath $GLOBAL:destinationpath
     Write-Host 'Successfull moved '($userinfo.SamAccountName) -ForegroundColor green
     }
    catch
     {
         $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
     }

return $newuser
 }

 function Import-SourceUserADObjects
 {
$remoteobjects = Get-RemoteMailbox -DomainController $GLOBAL:sourcedc
$targetou = 'UserAccounts'
#RecipientTypeDetails
#RemoteEquipmentMailbox
foreach ($remotemailbox in $remoteobjects)
{
Create-NewUser -useridentity $remotemailbox.SamAccountName
    if($remotemailbox.RecipientTypeDetails -eq 'RemoteEquipmentMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -Equipment  -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
        }
    }

    if($remotemailbox.RecipientTypeDetails -eq 'RemoteRoomMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -Room  -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
                 $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
        }
    }

    if($remotemailbox.RecipientTypeDetails -eq 'RemoteSharedMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -Shared  -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        #-ModeratedBy $remotemailbox.ModeratedBy
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
         write-host $_.ErrorDetails -ForegroundColor Magenta
        }
    }
        if($remotemailbox.RecipientTypeDetails -eq 'RemoteUserMailbox')
    {
    Write-Host 'Start to import '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
        try
        {
        Enable-RemoteMailbox -Identity $remotemailbox.SamAccountName -RemoteRoutingAddress $remotemailbox.RemoteRoutingAddress -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
        }
        catch
        {
         write-host $_.ErrorDetails -ForegroundColor Magenta
        }
    }
try
{
Write-Host 'Setting up additional attributes for '$remotemailbox.UserPrincipalName -BackgroundColor DarkGray
Set-RemoteMailbox -Identity $remotemailbox.UserPrincipalName -EmailAddressPolicyEnabled $false -SimpleDisplayName $remotemailbox.simpledisplayname -UserPrincipalName $remotemailbox.userprincipalname -CustomAttribute1 $remotemailbox.CustomAttribute1 -CustomAttribute2 $remotemailbox.CustomAttribute2 -CustomAttribute3 $remotemailbox.CustomAttribute3 -CustomAttribute4 $remotemailbox.CustomAttribute4 -CustomAttribute5 $remotemailbox.CustomAttribute5 -CustomAttribute6 $remotemailbox.CustomAttribute6 -CustomAttribute7 $remotemailbox.CustomAttribute7 -CustomAttribute8 $remotemailbox.CustomAttribute8 -CustomAttribute9 $remotemailbox.CustomAttribute9 -CustomAttribute10 $remotemailbox.CustomAttribute10 -CustomAttribute11 $remotemailbox.CustomAttribute11 -CustomAttribute12 $remotemailbox.CustomAttribute12 -CustomAttribute13 $remotemailbox.CustomAttribute13 -CustomAttribute14 $remotemailbox.CustomAttribute14 -CustomAttribute15 $remotemailbox.CustomAttribute15
Write-Host 'Configuration Import successful '$remotemailbox.UserPrincipalName -BackgroundColor Green
}
catch
{
Write-Host 'Configuration Import failed for '$remotemailbox.UserPrincipalName -BackgroundColor DarkMagenta

                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
Write-Host 'Adding attribute values to ADUser '
try
{
Write-Host 'Getting Source-Object guid'
$guid = Get-ADUser -Identity $remotemailbox.SamAccountName -Server $GLOBAL:sourceforest -Properties *
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
try
{
Write-Host 'Writing source objectGUID to the target ms-DS-ConsistencyGUID'
Get-ADUser -Identity $remotemailbox.SamAccountName  | Set-ADUser -Replace @{ "ms-Ds-ConsistencyGuid" = $guid.ObjectGUID.ToByteArray()}
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
try
{
Write-Host 'Writing source lagacyExchangeDN to the target lagacyExchangeDN'
Get-ADUser -Identity $remotemailbox.SamAccountName | Set-ADUser -Replace @{ "LegacyExchangeDN" = $remotemailbox.LegacyExchangeDN} -Verbose
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
try
{
Write-Host 'Writing source proxyaddresses to the target proxyaddresses'
Set-RemoteMailbox -Identity $remotemailbox.UserPrincipalName -EmailAddresses $remotemailbox.EmailAddresses
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
}


 }

  function Import-SourceGroupsADObjects
 {
$remoteobjects = Get-DistributionGroup -DomainController $GLOBAL:sourcedc
$targetou = 'UserAccounts'
#RecipientTypeDetails
#RemoteEquipmentMailbox
foreach ($remotemailbox in $remoteobjects)
{
    if($remotemailbox.RecipientTypeDetails -eq 'MailUniversalSecurityGroup')
    {
    Write-Host 'Start to import '$remotemailbox.SamAccountName -BackgroundColor DarkGray
        try
        {
        New-DistributionGroup -Name $remotemailbox.Name -SamAccountName $remotemailbox.SamAccountName -Type Security -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.SamAccountName -BackgroundColor Green
        }
        catch
        {
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
        }
    }

    if($remotemailbox.RecipientTypeDetails -eq 'MailUniversalDistributionGroup')
    {
    Write-Host 'Start to import '$remotemailbox.SamAccountName -BackgroundColor DarkGray
    Create-NewGroup -useridentity $remotemailbox.SamAccountName
        try
        {
        Enable-DistributionGroup -Identity $remotemailbox.SamAccountName -PrimarySmtpAddress $remotemailbox.PrimarySmtpAddress -ErrorAction stop
        Write-Host 'Import successful '$remotemailbox.SamAccountName -BackgroundColor Green
        }
        catch
        {
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
        }
    }

try
{
Write-Host 'Setting up additional attributes for '$remotemailbox.SamAccountName -BackgroundColor DarkGray
Set-DistributionGroup -Identity $remotemailbox.SamAccountName -EmailAddressPolicyEnabled $false -CustomAttribute1 $remotemailbox.CustomAttribute1 -CustomAttribute2 $remotemailbox.CustomAttribute2 -CustomAttribute3 $remotemailbox.CustomAttribute3 -CustomAttribute4 $remotemailbox.CustomAttribute4 -CustomAttribute5 $remotemailbox.CustomAttribute5 -CustomAttribute6 $remotemailbox.CustomAttribute6 -CustomAttribute7 $remotemailbox.CustomAttribute7 -CustomAttribute8 $remotemailbox.CustomAttribute8 -CustomAttribute9 $remotemailbox.CustomAttribute9 -CustomAttribute10 $remotemailbox.CustomAttribute10 -CustomAttribute11 $remotemailbox.CustomAttribute11 -CustomAttribute12 $remotemailbox.CustomAttribute12 -CustomAttribute13 $remotemailbox.CustomAttribute13 -CustomAttribute14 $remotemailbox.CustomAttribute14 -CustomAttribute15 $remotemailbox.CustomAttribute15
Write-Host 'Configuration Import successful '$remotemailbox.SamAccountName -BackgroundColor Green
}
catch
{
Write-Host 'Configuration Import failed for '$remotemailbox.SamAccountName -BackgroundColor DarkMagenta

                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
Write-Host 'Adding attribute values to ADGroup '$remotemailbox.SamAccountName -BackgroundColor DarkCyan
try
{
Write-Host 'Getting source objectGUID' -ForegroundColor DarkGray
$guid = Get-ADGroup -Identity $remotemailbox.SamAccountName -Server $GLOBAL:sourceforest -Properties * -ErrorAction stop
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
try
{
Write-Host 'Writing source objectGUID to the target ms-DS-ConsistencyGUID' -ForegroundColor DarkGray
Get-ADGroup $remotemailbox.SamAccountName | Set-ADGroup -Replace @{ "ms-Ds-ConsistencyGuid" = $guid.ObjectGUID.ToByteArray()}
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
try
{
Write-Host 'Writing source lagacyExchangeDN to the target lagacyExchangeDN' -ForegroundColor DarkGray
Get-ADGroup -Identity $remotemailbox.SamAccountName | Set-ADGroup -Replace @{ "LegacyExchangeDN" = $remotemailbox.LegacyExchangeDN} -Verbose
}
catch
{
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
}
try
{
Write-Host 'Writing source proxyaddresses to the target proxyaddresses' -ForegroundColor DarkGray
Get-DistributionGroup -Identity $remotemailbox.SamAccountName -ErrorAction stop | Set-DistributionGroup -EmailAddresses $remotemailbox.EmailAddresses -ErrorAction stop
}
catch
{
Write-Host 'Failed to Setup-Proxy addresses for '$remotemailbox.SamAccountName -BackgroundColor Magenta
                  $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
#Get-ADGroup -Identity $remotemailbox.SamAccountName -ErrorAction stop 
}
Write-Host 'Starting with GroupMembers migration'

$groupmembers = Get-DistributionGroupMember -Identity $remotemailbox.SamAccountName -DomainController $GLOBAL:sourcedc

 foreach($groupmember in $groupmembers)
 {
    write-host 'Adding '$groupmember' to '$remotemailbox -ForegroundColor DarkGray
    try
    {
    Add-ADGroupMember -Identity $remotemailbox.SamAccountName -Members $groupmember.SamAccountName -ErrorAction stop
    }
    catch
        {
         $mailusererror = $_.Exception.Message
            Write-Host $mailusererror -BackgroundColor DarkYellow
        }
 }

}


 }
