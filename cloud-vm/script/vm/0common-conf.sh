#!/bin/bash

# 遇到错误时停止执行后续语句
set -e
set -x

# 查看可用交换分区
# swapon
# 关闭交换分区, 删除或者注释行: swap.img, 避免重启 先临时关闭, 然后修改配置永久关闭
# 临时
swapoff -a
# 永久
sudo sed -i "s/^\/swap.img/# \/swap.img/" /etc/fstab

# 禁止 ipv4 地址转发
# sudo sed -i "s/#net\.ipv4\.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
# 应用 sysctl 参数而不重新启动
sudo sysctl --system

# 临时的，重启不生效
# sudo sysctl -w net.ipv4.ip_forward=1
# 以下命令同样临时效果
# echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# 配置 dns 服务
# if [ -f "/etc/systemd/resolved.conf" ];then
#     sed 's/#DNS=/DNS=223.5.5.5 1.1.1.1/' /etc/systemd/resolved.conf -i
#     sudo rm /etc/resolv.conf
#     ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
# fi