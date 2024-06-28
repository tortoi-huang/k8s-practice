#!ps

# 集群vm保存目录
$global:vm_os_iso = "~\Downloads\ubuntu-24.04-live-server-amd64.iso"
$global:vm_path = "C:\Users\ghuang11\vm"
$global:cluster_dir = "k8s"
New-Item -Path "$vm_path\" -Name $cluster_dir -ItemType "directory" -ErrorAction Ignore
$global:cluster_path = "$vm_path\$cluster_dir"
$global:disk_dir = "Virtual Hard Disks"
$global:vm_mem = 2GB
$global:vm_gen = 1
$global:vm_switch = "fix-switch"
