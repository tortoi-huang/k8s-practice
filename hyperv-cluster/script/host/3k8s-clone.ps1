#!ps
# 引用环境变量
& "$PSScriptRoot\0k8s-env.ps1"
$vm_temp = "k8s1"
# 先关闭模板虚拟机
Stop-VM $vm_temp

# 虚拟机k8s2
& "$PSScriptRoot\copy-vm.ps1" -t $vm_temp -d k8s2 -m $vm_master_mem -c $vm_master_cpus
& "$PSScriptRoot\copy-vm.ps1" -t $vm_temp -d k8s3 -m $vm_master_mem -c $vm_master_cpus
& "$PSScriptRoot\copy-vm.ps1" -t $vm_temp -d k8s4 -m $vm_node_mem -c $vm_node_cups
& "$PSScriptRoot\copy-vm.ps1" -t $vm_temp -d k8s5 -m $vm_node_mem -c $vm_node_cups