#!ps

# 创建新的交换机，名为fix-Switch， 类型为内部网络
New-VMSwitch -SwitchName "fix-Switch" -SwitchType Internal

# 查看交换机序号(ifIndex)，
Get-NetAdapter
# 设置交换机的ip地址，假设上面命令看到的ifIndex是137
New-NetIPAddress -IPAddress 192.168.98.1 -PrefixLength 24 -InterfaceIndex 137

# 配置交换机nat转换 name 为任意字符串, 所有192.168.98.0/24 ip均转发到改网络
New-NetNat -Name MyNATnetwork -InternalIPInterfaceAddressPrefix 192.168.98.0/24

# 查看已存在的nat网络
Get-NetNat

# 添加主机虚拟适配器连接到虚拟交换机
# Add-VMNetworkAdapter -ManagementOS -Name "fix-Switch host" -SwitchName fix-Switch
# Get-VMNetworkAdapter -ManagementOS
# # Remove-VMNetworkAdapter -ManagementOS -VMNetworkAdapterName "fix-Switch host"

# Get-NetAdapter -Name "vEthernet (fix-Switch host)"

# New-NetIPAddress -InterfaceAlias "vEthernet (fix-Switch host)" -IPAddress 192.168.98.2 -PrefixLength 24 -DefaultGateway 192.168.98.1
# # Remove-NetIPAddress -IPAddress 192.168.98.2 -InterfaceAlias "vEthernet (fix-Switch host)"