#Linked Mailbox provisioning

function Connect-ToExchangeOnprem()
{
$MyCredential = Get-Credential
Write-Host 'Lade Exchange-Snap-In' -ForegroundColor DarkGray

Write-Host 'Looking for Exchange-Modules' -ForegroundColor DarkGray
    #Add Exchange snapin if not already loaded
    if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"}))
    {
	    Write-Verbose "Loading the Exchange 2010 snapin"
	    try
	    {
		    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction STOP
	    }
	    catch
	    {
		    #Snapin not loaded
		    Write-Warning $_.Exception.Message
		    EXIT
	    }
	    . $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	    Connect-ExchangeServer -auto -AllowClobber -Credential $MyCredential
    }
}

$usercount = '20'

foreach ($counter in (0..$usercount))
{
    Write-Host 'Starting to create '('UserForestDemouser'+$counter) -ForegroundColor DarkGray
    try
    {
    New-ADUser -Surname ('DemoUser'+$counter) -Name ('UserForestDemouser'+$counter) -DisplayName ('UserForest Account '+$counter) -UserPrincipalName ('UserForest.Demouser'+$counter+'@onpremto.cloud')`
     -PasswordNeverExpires $true -Enabled $true -AccountPassword $password -SamAccountName ('UserForestDemouser'+$counter) -ErrorAction stop
     Enable-Mailbox -Identity ('UserForestDemouser'+$counter)
     Get-User -Identity ('UserForestDemouser'+$counter) | Set-User -LinkedMasterAccount ('user\'+('UserForestDemouser'+$counter)) -LinkedDomainController 'dc01.user.onpremto.cloud' -LinkedCredential:$linkedcred
     Write-Host 'Sucessfull created '('UserForestDemouser'+$counter) -ForegroundColor green
    }
    catch
    {
             write-host $_.ErrorDetails -ForegroundColor Magenta

     }
    try
    {
     Write-Host 'Starting to move '('UserForestDemouser'+$counter) -ForegroundColor DarkGray
     Move-ADObject -Identity ('CN='+('UserForestDemouser'+$counter)+',CN=Users,DC=User,DC=onpremto,DC=cloud') -TargetPath ('OU=UserAccounts,DC=User,DC=onpremto,DC=cloud')
     Write-Host 'Successfull moved '('UserForestDemouser'+$counter) -ForegroundColor green
     }
    catch
     {
      write-host $_.ErrorDetails -ForegroundColor Magenta
     }

 }
