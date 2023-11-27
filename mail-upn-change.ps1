#UserPrincipalName

$wrongusers = Get-ADUser -Properties * -Filter * 
$newdomainsuffix = 'onpremto.cloud'
foreach ($wronguser in $wrongusers)
{
$newupn = ($wronguser.UserPrincipalName).Split('@')[0]
Write-Host 'Change mail for '$wronguser.samaccountname -ForegroundColor DarkGray
Set-ADUser -Identity $wronguser.samaccountname -Replace @{"mail" = ($newupn+'@'+$newdomainsuffix)} 
Write-Host 'Mail Changed' -ForegroundColor Green
}

foreach ($wronguser in $wrongusers)
{
$newupn = ($wronguser.UserPrincipalName).Split('@')[0]
Write-Host 'Change UPN for '$wronguser.samaccountname -ForegroundColor DarkGray
Set-ADUser -Identity $wronguser.samaccountname -UserPrincipalName ($newupn+'@'+$newdomainsuffix)
Write-Host 'UPN Changed' -ForegroundColor Green
}
