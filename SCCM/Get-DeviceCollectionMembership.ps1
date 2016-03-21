$ResID = (Get-CMDevice -Name "mn001cpnb00u5pk").ResourceID
$Collections = (Get-WmiObject -computername mn001h5a064 -Class sms_fullcollectionmembership -Namespace root\sms\site_CH1 -Filter "ResourceID = '$($ResID)'").CollectionID
foreach ($Collection in $Collections)
{
    Get-CMDeviceCollection -CollectionId $Collection | select Name, CollectionID
}