#User provisioning

Add-PSSnapin *RecipientManagement

$usercount = '100'
[System.Security.SecureString]$password = Read-Host -AsSecureString

foreach ($counter in (0..$usercount))
{
    Write-Host 'Starting to create '('UserForestDemouser'+$counter) -ForegroundColor DarkGray
    try
    {
    New-ADUser -Surname ('DemoUser'+$counter) -Name ('UserForestDemouser'+$counter) -DisplayName ('UserForest Account '+$counter) -UserPrincipalName ('UserForest.Demouser'+$counter+'@onpremto.cloud')`
     -PasswordNeverExpires $true -Enabled $true -AccountPassword $password -SamAccountName ('UserForestDemouser'+$counter) -ErrorAction stop
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
 
