#!ps

# 引用环境变量
& "$PSScriptRoot\0k8s-env.ps1"

# 删除集群
Remove-VM k8s* -Force
Remove-Item -Path $cluster_path\k8s* -Recurse -Force

# 删除nat网络
Remove-NetNat -Name $nat_net
# 删除交换机
Remove-VMSwitch -SwitchName $vm_switch -Force