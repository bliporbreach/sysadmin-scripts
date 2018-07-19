
Import-Module VMware.DeployAutomation

Write-Host "This script schedules an upgrade for VM Hardware to version 13 (ESXi 6.5) on all VMs on a vCenter server."
Write-Host "The upgrade occurs on the next reboot of the VM. Even though the script applies the change only to VMs running"
Write-Host "the most recent version of VMware Tools, the process is IRREVERSIBLE. Make sure all hosts within your clusters"
Write-Host "have been upgraded to ESXi 6.5 before proceeding. PLEASE USE WITH CAUTION!"
$VMs = @()
$vCenter = Read-Host -Prompt "Enter the FQDN or hostname of the target vCenter server"
Connect-VIServer $vCenter

New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force

$VMs = Get-VM | Where-Object {($_.ToolsVersionStatus -Like "*Current*") -and ($_.Version -ne "v13")} | Select Name, ToolsVersion, ToolsVersionStatus, Version
Write-Host "The following VMs will be upgraded to VMware Hardware version 13 (6.5) upon next reboot:"
$VMs | Format-Table

$confirm = Read-Host -Prompt "Do you want to proceed (Y/N)?"
if (($confirm -eq "Y") -or ($confirm -eq "y")) {
    foreach ($VM in $VMs) {
        $target = Get-VM $VM.Name
        $task = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec
        $task.ScheduledHardwareUpgradeInfo = New-Object -TypeName VMware.Vim.ScheduledHardwareUpgradeInfo
        $task.ScheduledHardwareUpgradeInfo.UpgradePolicy = "always"
        $task.ScheduledHardwareUpgradeInfo.VersionKey = "vmx-13"
        $target.ExtensionData.ReconfigVM_Task($task)
    }

}



