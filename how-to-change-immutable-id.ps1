#ObjectGUID to ImmutableID
$aduser = Get-ADUser UserForestDemouser76 -Properties *

 $immutableid = [Convert]::ToBase64String([guid]::New($aduser.ObjectGUID).ToByteArray())


 $immutableid = [Convert]::ToBase64String([guid]::New("beefc282-846b-4b81-a7ec-7796d0acda81").ToByteArray())


 #ObjectGUID to ms-DS-ConsistancyGUID
 $aduser = Get-ADUser UserForestDemouser76 -Properties *

 $msdsconsistancyguid = $aduser.ObjectGUID.ToByteArray()

#Change ImmutableID

Connect-AzureAD
Get-AzureADUser -SearchString 'UserForest.Demouser76' | select 'immutableid'
Get-AzureADUser -SearchString 'UserForest.Demouser76' | Set-AzureADUser -ImmutableId $immutableid
