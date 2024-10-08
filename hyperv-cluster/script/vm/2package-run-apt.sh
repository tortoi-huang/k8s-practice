#!/bin/bash

# 遇到错误时停止执行后续语句
set -e
set -x

if [ "$EUID" -ne 0 ]; then
  echo "此脚本必须以特权身份（root用户）执行。" >&2
  exit 1

fi
if command -v containerd&> /dev/null; then
    echo "containerd 命令已经存在"
    exit 1
fi

# 安装 cni 网络插件
sudo mkdir -p /opt/cni/bin
wget -qO- https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz | sudo tar -C /opt/cni/bin -xvz 
echo -e "export CNI_PATH=/opt/cni/bin" | sudo tee -a /etc/profile
source /etc/profile

apt install containerd -y