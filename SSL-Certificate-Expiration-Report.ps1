
# ----------------------------------------------------------------
# Description: Checks the status of SSL certificates for URLs
# specified in the input file and sends e-mails for all certificates
# as well as the ones expiring soon
# ----------------------------------------------------------------

# Command line arguments
param (
	[Parameter(Mandatory)]
	[string]$FilePath,
	[Parameter()]
	[string]$EmailServer = "mailhost.moorecap.com",
	[Parameter(Mandatory)]
	[string]$EmailAddressTo,
    	[Parameter()]
  	[string]$EmailAddressFrom,
    	[Parameter()]
	[string]$minimumCertAgeDays = 60
)

# Varilable Declaration
$timeoutMilliseconds = 10000
$urls = (Get-Content $FilePath) -notmatch '^#'
$certs = @()
$expiringCerts = @()

# Define formatting for the HTML e-mail
$formatting = "<style>"
$formatting = $formatting + "BODY{Font-Family: Tahoma; Font-Size: 9pt;}"
$formatting = $formatting + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; Font-Family: Tahoma; Font-Size: 9pt;}"
$formatting = $formatting + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:blue}"
$formatting = $formatting + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
$formatting = $formatting + "</style>"

# Disabling the cert validation check. This is what makes this whole thing work with invalid certs.
 [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Go to each URL, fetch the cert info and add it to the $certs custom object array
foreach ($url in $urls) {
    Write-Host Checking $url -f Green
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Timeout = $timeoutMilliseconds
    try {$req.GetResponse() |Out-Null} catch {Write-Host Exception while checking URL $url`: $_ -f Red}
    $objCert = New-Object System.Object
    $objCert | Add-Member -Type NoteProperty -Name URL -Value $url
    $objCert | Add-Member -Type NoteProperty -Name Name -Value $req.ServicePoint.Certificate.GetName()
    $objCert | Add-Member -Type NoteProperty -Name SerialNumber -Value $req.ServicePoint.Certificate.GetSerialNumberString()
    $objCert | Add-Member -Type NoteProperty -Name Thumbprint -Value $req.ServicePoint.Certificate.GetCertHashString()
    $objCert | Add-Member -Type NoteProperty -Name EffectiveDate -Value $req.ServicePoint.Certificate.GetEffectiveDateString()
    $objCert | Add-Member -Type NoteProperty -Name ExpirationDate -Value $req.ServicePoint.Certificate.GetExpirationDateString()
    $objCert | Add-Member -Type NoteProperty -Name Issuer -Value $req.ServicePoint.Certificate.GetIssuerName()    
    $certs += $objCert  
 }

# Show all certificates
Write-Host "ALL CERTIFICATES"
Write-Host "----------------"
$certs | Format-List

# Find certificates that are expiring in $minimumCertAgeDays days 
foreach ($cert in $certs) {
    $expiration = [datetime]::ParseExact($cert.ExpirationDate, "M/d/yyyy h:mm:ss tt",$null) 
    [int]$certExpiresIn = ($expiration - $(get-date)).Days
    if ($certExpiresIn -lt $minimumCertAgeDays) {
        $expiringCerts += $cert
    }
}

# Show certificates that are expiring
Write-Host "EXPIRING CERTIFICATES"
Write-Host "---------------------"
$expiringCerts | Format-List


# Send an e-mail containing all certificates
 if ($certs) {
    $message = $certs | Select URL, Name, EffectiveDate, ExpirationDate, Issuer | ConvertTo-Html -Head $formatting | Out-String
    Send-MailMessage -SmtpServer $EmailServer -From $EmailAddressFrom -To $EmailAddressTo -Subject "INFORMATIONAL: SSL Certificate Report" -Body $message -BodyAsHtml 
    }

# Send an e-mail containing only certificates that are about to expire
 if ($expiringCerts) {
    $message = $expiringCerts | Select URL, Name, EffectiveDate, ExpirationDate, Issuer | ConvertTo-Html -Head $formatting | Out-String
    Send-MailMessage -SmtpServer $EmailServer -From $EmailAddressFrom -To $EmailAddressTo -Subject "WARNING: SSL Certificates expiring in $minimumCertAgeDays days!" -Body $message -BodyAsHtml 
    }

