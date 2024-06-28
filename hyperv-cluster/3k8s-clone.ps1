#!ps
# 引用环境变量
& "$PSScriptRoot\0k8s-env.ps1"
$vm_temp = "k8s1"

# 虚拟机k8s2
$vm_name = "k8s2"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-Item -Path "$cluster_path\$vm_name\" -Name $disk_dir -ItemType "directory"
# 复制 k8s1 的磁盘
Copy-Item "$cluster_path\$vm_temp\$disk_dir\$vm_temp.vhdx" -Destination "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"

# 虚拟机k8s3
$vm_name = "k8s3"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-Item -Path "$cluster_path\$vm_name\" -Name $disk_dir -ItemType "directory"
Copy-Item "$cluster_path\$vm_temp\$disk_dir\$vm_temp.vhdx" -Destination "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"

# 虚拟机k8s4
$vm_name = "k8s4"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-Item -Path "$cluster_path\$vm_name\" -Name $disk_dir -ItemType "directory"
Copy-Item "$cluster_path\$vm_temp\$disk_dir\$vm_temp.vhdx" -Destination "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"

# 虚拟机k8s5
$vm_name = "k8s5"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-Item -Path "$cluster_path\$vm_name\" -Name $disk_dir -ItemType "directory"
Copy-Item "$cluster_path\$vm_temp\$disk_dir\$vm_temp.vhdx" -Destination "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"
