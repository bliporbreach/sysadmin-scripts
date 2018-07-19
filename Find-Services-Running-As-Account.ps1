Write-Host "---------------------------------------------------------------------------------"
Write-Host "GET-SERVICE-RUNAS.PS1 VER 1.0 BY KAMYAR KOJOURI"
Write-Host "This script helps you search your environment to identify services that have been"
Write-Host "configured to run as a specified user. Run it before resetting account passwords "
Write-Host "to find services that will potentially break as a result of the change."
Write-Host "---------------------------------------------------------------------------------"

# Import Active Directory Module
Write-Host "`nImporting Active Directory module"
Import-Module ActiveDirectory

# Get user input
$LogonAccount = Read-Host 'Please enter the user account (ex. contoso\administrator)'
$OU = Read-Host 'Please enter the DN of the search base OU (ex. OU=Servers, DC=contoso, DC=com)'
$csvPath = Read-Host 'Please enter the path of the output CSV file (the default is .\output.csv)'

# Define and clear the arrays
$services = @()
$computers = @()
$i=0 # Counter for progress bar

# Find Windows machines in the specified OU
Write-Host "Looking for all Windows machines in the specified OU..."
$computers = Get-ADComputer -SearchBase $OU -Filter 'OperatingSystem -like "*Windows*"' | select -ExpandProperty Name

# Loop to go through each computer and find the services
Write-Host "Scanning the machines for services matching the specified criteria...`n"
foreach ($computer in $computers)
{
    Write-Progress -Activity "Scanning machines..." `
            -Status "Scanned $i of $($computers.count)" -PercentComplete (($i / $computers.count) * 100)
    if (Test-Connection $computer -Quiet) {
        Write-Host $computer
        $services += Get-WmiObject win32_service -ComputerName $computer | Where {$_.StartName -like "*$LogonAccount*"}
    }
    else {
        Write-Host "$computer is offline"
    }
    $i++
}

# Output
Write-Host "`n`nServices running as $LogonAccount in $OU`n"
$services | select SystemName,Name,DisplayName | ft

Write-Host "`nExporting to CSV"
if ([string]::IsNullOrEmpty($csvPath)) { $csvPath=".\output.csv"}
$services | select SystemName,Name,DisplayName | Export-Csv -Path $csvPath
