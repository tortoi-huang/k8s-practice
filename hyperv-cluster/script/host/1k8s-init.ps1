#!ps

# 引用环境变量
& "$PSScriptRoot\0k8s-env.ps1"

# 创建新的交换机，名为$vm_switch， 类型为内部网络
New-VMSwitch -SwitchName $vm_switch -SwitchType Internal
# 查看交换机及其所有属性
# get-vmswitch $vm_switch|select *

# 查看交换机序号(ifIndex)，
# Get-NetAdapter -Name "vEthernet ($vm_switch)"|select-Object -First 1 { Write-Output $_.ifIndex } 
# 设置交换机的ip地址，假设上面命令看到的ifIndex是137
# New-NetIPAddress -IPAddress 192.168.98.1 -PrefixLength 24 -InterfaceIndex 137
New-NetIPAddress -IPAddress $nat_gateway -PrefixLength $nat_prefix_len -InterfaceAlias "vEthernet ($vm_switch)"
# Get-NetIPAddress -InterfaceAlias "vEthernet ($vm_switch)"

# 配置交换机nat转换 name 为任意字符串, 所有192.168.98.0/24 ip均转发到改网络, 可以通过 ExternalIPInterfaceAddressPrefix 指定外部地址, 默认为空, 转发到系统默认上网网卡
New-NetNat -Name $nat_net -InternalIPInterfaceAddressPrefix $nat_subnet

# 查看已存在的nat网络
# Get-NetNat -Name $nat_net

# 添加主机虚拟适配器连接到虚拟交换机
# Add-VMNetworkAdapter -ManagementOS -Name "$host_adapter" -SwitchName $vm_switch
# Get-VMNetworkAdapter -ManagementOS -Name "$host_adapter"
# # Remove-VMNetworkAdapter -ManagementOS -VMNetworkAdapterName "$host_adapter"

# Get-NetAdapter -Name "vEthernet ($host_adapter)"

# New-NetIPAddress -InterfaceAlias "vEthernet ($host_adapter)" -IPAddress 192.168.98.2 -PrefixLength 24 -DefaultGateway 192.168.98.1
# # Remove-NetIPAddress -IPAddress 192.168.98.2 -InterfaceAlias "vEthernet ($host_adapter)"