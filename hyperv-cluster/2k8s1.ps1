#!ps

# 引用环境变量
& "$PSScriptRoot\0k8s-env.ps1"

# 虚拟机k8s1
$vm_name = "k8s1"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-VHD -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx" -SizeBytes 127GB
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"
Add-VMDvdDrive -VMName $vm_name -Path $vm_os_iso
# 启用嵌套虚拟化
Set-VMProcessor -ExposeVirtualizationExtensions $true -VMName $vm_name

# Start-VM -Name k8s1
# Enter-PSSession -VMName k8s1