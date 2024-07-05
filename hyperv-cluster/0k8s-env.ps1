#!ps

# 集群vm保存目录
$global:vm_os_iso = "$HOME\Downloads\ubuntu-24.04-live-server-amd64.iso"
$global:vm_path = "$HOME\vm"
$global:cluster_dir = "k8s"
New-Item -Path "$vm_path\" -Name $cluster_dir -ItemType "directory" -ErrorAction Ignore
$global:cluster_path = "$vm_path\$cluster_dir"
$global:disk_dir = "Virtual Hard Disks"
$global:vm_mem = 2GB
$global:vm_gen = 1
$global:vm_switch = "hyperv_switch_fix"
$global:nat_net = "hyperv_nat_fix"
$global:host_adapter = "fix_vm_adapter"

$global:nat_prefix_len = 24
$global:nat_subnet = "192.168.98.0/$nat_prefix_len"
$global:nat_gateway = "192.168.98.1"
