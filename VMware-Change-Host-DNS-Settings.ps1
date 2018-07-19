Import-Module VMware.VimAutomation.Core

$vCenter = Read-Host "Enter the vCenter server's hostname"
$dnspri = read-host "Enter Primary DNS"
$dnsalt = read-host "Enter Alternate DNS"

Connect-VIServer $vCenter

$esxHosts = get-VMHost

foreach ($esxHost in $esxHosts) {
    Write-Host "Configuring DNS on $esxHost..."
    Get-VMHostNetwork -VMHost $esxHost | Set-VMHostNetwork -DnsAddress $dnspri, $dnsalt
}
