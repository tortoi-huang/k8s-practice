#!ps

# 创建新的交换机，名为fix-Switch， 类型为内部网络
New-VMSwitch -SwitchName "fix-Switch" -SwitchType Internal

# 查看交换机序号(ifIndex)，
Get-NetAdapter
# 设置交换机的ip地址，假设上面命令看到的ifIndex是137
New-NetIPAddress -IPAddress 192.168.98.1 -PrefixLength 24 -InterfaceIndex 137

# 配置交换机nat转换 name 为任意字符串
New-NetNat -Name MyNATnetwork -InternalIPInterfaceAddressPrefix 192.168.98.0/24

# 查看已存在的nat网络
Get-NetNat

# 集群vm保存目录
$vm_path = "C:\Users\ghuang11\vm"
$cluster_dir = "k8s"
New-Item -Path "$vm_path\" -Name $cluster_dir -ItemType "directory"
$cluster_path = "$vm_path\$cluster_dir"
$disk_dir = "Virtual Hard Disks"
$vm_mem = 4GB
$vm_gen = 1

# 虚拟机k8s1
$vm_name = "k8s1"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName "Default Switch"
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-VHD -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx" -SizeBytes 127GB
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"

# Remove-VM k8s1 -Force
# Remove-Item -Path C:\Users\ghuang11\vm\k8s\k8s1 -Recurse -Force
# TODO 配置虚拟机: 安装操作系统，配置ip地址， 安装配置软件包括kubernetes

$vm_temp = "k8s1"
$vm_switch = "fix-switch"

# 虚拟机k8s2
$vm_name = "k8s2"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-Item -Path "$cluster_path\$vm_name\" -Name $disk_dir -ItemType "directory"
# 复制 k8s1 的磁盘创建虚拟机2减少配置
Copy-Item "$cluster_path\$vm_temp\$disk_dir\$vm_temp.vhdx" -Destination "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx" -Recurse
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"

# 虚拟机k8s3
$vm_name = "k8s3"
New-VM -Name $vm_name -MemoryStartupBytes $vm_mem -Path "$cluster_path" -Generation $vm_gen -SwitchName $vm_switch
Set-VMProcessor $vm_name -Count 4 -Reserve 10 -Maximum 75 -RelativeWeight 200

New-Item -Path "$cluster_path\$vm_name\" -Name $disk_dir -ItemType "directory"
Copy-Item "$cluster_path\$vm_temp\$disk_dir\$vm_temp.vhdx" -Destination "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx" -Recurse
Add-VMHardDiskDrive -VMName $vm_name -Path "$cluster_path\$vm_name\$disk_dir\$vm_name.vhdx"

# 启动所有vm
Start-VM -Name k8s*
Stop-VM -Name k8s*

# 删除集群
# Remove-VM k8s* -Force
# Remove-Item -Path $cluster_path -Recurse -Force