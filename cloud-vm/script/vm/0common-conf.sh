#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

script_dir="$(dirname "$0")"

output=$(grep $(hostname -I) $script_dir/env.profile)
if [ -z "$output" ]; then
    echo "invalidate environment variables"
    exit 1
fi

source $script_dir/env.profile
if [ ! -n "$LOADBALANCE_VIP" ]; then 
    echo "environment variables are not set "
    exit 1
fi
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

# 配置环境变量
sudo tee -a /etc/profile <<-EOF
export APISERVER_DEST_PORT=${APISERVER_DEST_PORT}
export APISERVER_SRC_PORT=${APISERVER_SRC_PORT}
export APISERVER_ADVERTISE_ADDRESS=${APISERVER_ADVERTISE_ADDRESS}
export LOADBALANCE_VIP=${LOADBALANCE_VIP}
export CONTROL_NODE1=${CONTROL_NODE1}
export CONTROL_NODE2=${CONTROL_NODE2}
export CONTROL_NODE3=${CONTROL_NODE3}
export DATA_NODE1=${DATA_NODE1}
export DATA_NODE2=${DATA_NODE2}
EOF
source /etc/profile


# 依赖前面配置需要重新登录
# 配置hosts文件
sudo sed /k8s1/d /etc/hosts -i
cat <<EOF | sudo tee -a /etc/hosts

${CONTROL_NODE1} k8s1
${CONTROL_NODE2} k8s2
${CONTROL_NODE3} k8s3
${DATA_NODE1} k8s4
${DATA_NODE2} k8s5
${LOADBALANCE_VIP} cluster-endpoint
EOF

# ubuntu 的服务自动重启
if command -v needrestart&> /dev/null; then
    sed "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf -i
fi

# 配置 dns 服务
if [ -f "/etc/systemd/resolved.conf" ];then
    sed 's/#DNS=/DNS=223.5.5.5 1.1.1.1/' /etc/systemd/resolved.conf -i
    sudo rm /etc/resolv.conf
    ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi