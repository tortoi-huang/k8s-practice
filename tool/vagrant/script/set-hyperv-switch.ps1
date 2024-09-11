# See: https://www.thomasmaurer.ch/2016/01/change-hyper-v-vm-switch-of-virtual-machines-using-powershell/

& "$PSScriptRoot\0k8s-env.ps1"
Get-VM "ubt1" | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "$vm_switch"