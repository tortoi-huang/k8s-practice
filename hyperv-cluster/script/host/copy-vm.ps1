# param 必须放在第一个命令
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string] $t = $(throw "-t parameter is required."),
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string]$d = $(throw "-d parameter is required."),
    [Parameter(Mandatory=$false)] [int64]$m=2GB,
    [Parameter(Mandatory=$false)] [int]$c=2
)

& "$PSScriptRoot\0k8s-env.ps1"

If([String]::IsNullOrEmpty($cluster_path)){
    Write-Host "The cluster_path is null or empty."
    exit 1
}
If([String]::IsNullOrEmpty($disk_dir)){
    Write-Host "The disk_dir is null or empty."
    exit 1
}

$vmswitch=get-vmswitch|Where-Object -Property Name -EQ -Value $vm_switch
If($null -eq $vmswitch){
    Write-Host "There is no a vm switch named '$vm_switch'."
    exit 1
}

Write-Output "template vm: $t"
Write-Output "new vm: $d, memery: $m, cpu count: $c, generation $vm_gen, with exists vm switch $vm_switch"
Write-Output "new vm disk: $cluster_path\$d\$disk_dir\$d.vhdx"

Stop-VM $t

New-VM -Name $d -MemoryStartupBytes $m -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $d -Count $c -Reserve 10 -Maximum 75 -RelativeWeight 200
Set-VMMemory $d -DynamicMemoryEnabled $false

New-Item -Path "$cluster_path\$d\" -Name $disk_dir -ItemType "directory"
# 复制磁盘
Copy-Item "$cluster_path\$t\$disk_dir\$t.vhdx" -Destination "$cluster_path\$d\$disk_dir\$d.vhdx"
Add-VMHardDiskDrive -VMName $d -Path "$cluster_path\$d\$disk_dir\$d.vhdx"