#!/bin/bash

set -x

# 安装go, 下载并设置环境变量
wget -qO- https://dl.google.com/go/go1.22.5.linux-amd64.tar.gz | sudo tar -C /usr/local -xvz
echo -e "\nexport GOPATH=\$HOME/go\nexport GOROOT=/usr/local/go" | sudo tee -a /etc/profile
# 生成软连接到 /usr/local/bin, 因为 sudo 无法读取path变量, 不能通过设置path变量方式处理
sudo ln -s /usr/local/go/bin/go /usr/local/bin/go
source /etc/profile

#安装runc, 通过源码编译安装, 参考: https://github.com/opencontainers/runc
sudo apt install libseccomp-dev -y
sudo apt install make git gcc pkg-config -y
mkdir -p $GOPATH/src/github.com/opencontainers
cd $GOPATH/src/github.com/opencontainers
git clone https://github.com/opencontainers/runc
cd runc
make
sudo make install
cd ..
rm -rf runc

# 安装 cni 网络插件
sudo mkdir -p /opt/cni/bin
wget -qO- https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz | sudo tar -C /opt/cni/bin -xvz 
echo -e "export CNI_PATH=/opt/cni/bin" | sudo tee -a /etc/profile
source /etc/profile

# 安装 containerd 容器运行时, https://github.com/containerd/containerd/blob/main/docs/getting-started.md
wget -qO- https://github.com/containerd/containerd/releases/download/v1.7.19/containerd-1.7.19-linux-amd64.tar.gz | sudo tar Cxzv /usr/local 
# 使用系统服务配置systemd作为默认的cgroup管理程序
sudo mkdir /usr/local/lib/systemd/system/ -p
sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /usr/local/lib/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd