$inputfile = Read-Host("Enter the path to the file containing a list of HP iLOs by hostname or IP address")
$outputfile = Read-Host("Enter the path to the output CSV file")
$targets = Get-Content $inputfile
$iLOS = @()

# Script block to bypass SSL warnings
# -----------------------------------
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#-------------------------------------

foreach ($target in $targets) {
    [xml]$xml = (Invoke-WebRequest "https://$target/xmldata?item=CpqKey").Content

    $iLO = New-Object -TypeName PSObject
    $iLO | Add-Member -MemberType NoteProperty -Name Target -Value $target
    $iLO | Add-Member -MemberType NoteProperty -Name Name -Value $xml.PROLIANTKEY.LNAME
    $iLO | Add-Member -MemberType NoteProperty -Name Key -Value $xml.PROLIANTKEY.KEY
    $iLO | Add-Member -MemberType NoteProperty -Name SN -Value $xml.PROLIANTKEY.SN
    $iLO | Add-Member -MemberType NoteProperty -Name SBSN -Value $xml.PROLIANTKEY.SBSN

    $iLOs += $iLO
}

$iLOs | Format-Table
$iLOs | Export-Csv($outputfile)

