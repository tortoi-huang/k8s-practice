# See: https://www.petri.com/using-nat-virtual-switch-hyper-v

& "$PSScriptRoot\0k8s-env.ps1"
If ("$vm_switch" -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    'Creating Internal-only switch named "$vm_switch" on Windows Hyper-V host...'

    New-VMSwitch -SwitchName "$vm_switch" -SwitchType Internal

    New-NetIPAddress -IPAddress $nat_gateway -PrefixLength $nat_prefix_len -InterfaceAlias "vEthernet ($vm_switch)"

    New-NetNAT -Name "$nat_net" -InternalIPInterfaceAddressPrefix $nat_subnet
}
else {
    '"$vm_switch" for static IP configuration already exists; skipping'
}

If ("$nat_gateway" -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress) -eq $FALSE) {
    'Registering new IP address $nat_gateway on Windows Hyper-V host...'

    New-NetIPAddress -IPAddress $nat_gateway -PrefixLength $nat_prefix_len -InterfaceAlias "vEthernet ($vm_switch)"
}
else {
    '"$nat_gateway" for static IP configuration already registered; skipping'
}

If ("$nat_subnet" -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix) -eq $FALSE) {
    'Registering new NAT adapter for $nat_subnet on Windows Hyper-V host...'

    New-NetNAT -Name "$nat_net" -InternalIPInterfaceAddressPrefix $nat_subnet
}
else {
    '"$nat_subnet" for static IP configuration already registered; skipping'
}