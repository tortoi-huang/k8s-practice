# 创建kubernetes集群

## 规划
创建一个虚拟交换机

子网为 192.168.98.0/24, 网关为 192.168.98.1

创建5个虚拟机
1. ip: 192.168.98.201, hostname: k8s1 (master etcd)
2. ip: 192.168.98.202, hostname: k8s2 (master etcd)
3. ip: 192.168.98.203, hostname: k8s3 (master etcd)
3. ip: 192.168.98.204, hostname: k8s4 (node)
3. ip: 192.168.98.205, hostname: k8s5 (node)

虚拟机可以通过 nat 访问网络，并搭建五个节点的 kubernetes 集群。

## 宿主机配置
复制 config 文件到宿主机用户目录 ~/.ssh/ 下

```powershell
# 看是否已经有默认的ssh 密钥，如果没有则使用生成
# ssh-keygen
# 设置脚本执行策略
# Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```
## 创建交换机
```bash
.\1k8s-init.ps1
```

## 创建虚拟机
```powershell
.\2k8s1.ps1
# 启动虚拟机
Start-VM k8s1
```
# 安装和配置虚拟机
安装时注意选择手动设置ip地址，避免安装好后无法获取ip和无法连接网络
subnet: 192.168.98.0/24
adress: 192.168.98.201
name server: 223.5.5.5,1.1.1.1

安装用户名: huang

## 配置ubuntu
```bash
# ssh huang@192.168.98.201

# 查看可用交换分区
swapon
# 关闭交换分区, 删除或者注释行: swap.img
sudo sed -i "s/^\/swap.img/# \/swap.img/" /etc/fstab

#配置hosts文件
sudo sed /k8s1/d /etc/hosts -i
echo -e "\n192.168.98.201 k8s1\n192.168.98.202 k8s2\n192.168.98.203 k8s3\n192.168.98.204 k8s4\n192.168.98.205 k8s5"| sudo tee -a /etc/hosts
# 检查主机唯一标识
ip link
sudo cat /sys/class/dmi/id/product_uuid

sudo apt update
sudo apt upgrade -y
# 重启
sudo systemctl poweroff

```

## 安装kubernetes及其依赖
```bash
# 安装容器运行时
# 安装go, 下载并设置环境变量
curl -O https://dl.google.com/go/go1.22.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
echo -e "\nexport GOPATH=\$HOME/go\nexport GOROOT=/usr/local/go" | sudo tee -a /etc/profile
# 生成软连接到 /usr/local/bin, 因为 sudo 无法读取path变量, 不能通过设置path变量方式处理
ln -s /usr/local/go/bin/go /usr/local/bin/go

#安装runc, 通过源码编译安装, 参考: https://github.com/opencontainers/runc
sudo apt install libseccomp-dev
sudo apt install make git gcc pkg-config -y
mkdir -p $GOPATH/src/github.com/opencontainers
cd $GOPATH/src/github.com/opencontainers
git clone https://github.com/opencontainers/runc
cd runc
make
sudo make install

# 下载 cni 网络插件, 似乎curl无法下载, 因为该地址会返回一个302
wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
sudo tar -xvf cni-plugins-linux-amd64-v1.5.1.tgz -C /opt/cni/bin
echo -e "export CNI_PATH=/opt/cni/bin" | sudo tee -a /etc/profile

# 安装 containerd 容器运行时, https://github.com/containerd/containerd/blob/main/docs/getting-started.md
wget https://github.com/containerd/containerd/releases/download/v1.7.19/containerd-1.7.19-linux-amd64.tar.gz
# 解压可执行文件到 /usr/local/bin, 实际可以解压到任意目录然后通过软连接创建到 /usr/local/bin
sudo tar Cxzvf /usr/local containerd-1.7.19-linux-amd64.tar.gz
# 使用系统服务配置systemd作为默认的cgroup管理程序
sudo mkdir /usr/local/lib/systemd/system/ -p
sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /usr/local/lib/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
# 配置镜像仓库, https://github.com/containerd/containerd/blob/main/docs/hosts.md
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
# # TODO 以下配置需要手工修改
# cat <<EOF | sudo tee /etc/containerd/config.toml
# version = 2

# [plugins."io.containerd.grpc.v1.cri".registry]
#    config_path = "/etc/containerd/certs.d"
# EOF
# # 配置华为镜像仓库 https://085aa6fdb500267d0f7dc013da257e20.mirror.swr.myhuaweicloud.com
# sudo mkdir /etc/containerd/certs.d/docker.io -p
# cat <<EOF | sudo tee /etc/containerd/certs.d/docker.io/hosts.toml
# server = "https://docker.io"

# [host."https://085aa6fdb500267d0f7dc013da257e20.mirror.swr.myhuaweicloud.com"]
#   capabilities = ["pull", "resolve"]

# # [host."https://registry-1.docker.io"]
# #   capabilities = ["pull", "resolve"]
# EOF

# sudo mkdir /etc/containerd/certs.d/registry.k8s.io -p
# cat <<EOF | sudo tee /etc/containerd/certs.d/registry.k8s.io/hosts.toml
# server = "https://registry.k8s.io"

# [host."https://085aa6fdb500267d0f7dc013da257e20.mirror.swr.myhuaweicloud.com"]
#   capabilities = ["pull", "resolve"]
#   override_path = true
# EOF

# 测试 containerd
# sudo ctr i pull docker.io/library/nginx:1.27.0
# sudo ctr i pull hub.atomgit.com/amd64/nginx:1.25.2-perl
# sudo ctr run -rm --net-host hub.atomgit.com/amd64/nginx:1.25.2-perl ng1
# curl localhost
# sudo ctr i rm hub.atomgit.com/amd64/nginx:1.25.2-perl

# 安装kubernetes 依赖工具
sudo apt install -y apt-transport-https gpg
# 下载软件包仓库签名， 这里版本不重要，所有版本的前面都是一样的
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# 添加k8s软件仓库
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# 安装 kubelet kubeadm kubectl
sudo apt install -y kubelet kubeadm kubectl
# 标记为hold 防止自动更新
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 查看 kubelet 运行状态
sudo systemctl status kubelet
# 查看kubelet日志
# journalctl -fu kubelet
```

# 复制虚拟机

```bash
.\3k8s-clone.ps1
```

# 配置各个虚拟机的ip地址
因为克隆了模板机的 ip 配置会有 ip 冲突，需要逐个虚拟机启动进行配置
```bash
# 配置k8s2 ip
Start-VM k8s2
ssh huang@192.168.98.201
# sudo sed -i "s/192.168.98.201\/24/192.168.98.202\/24/g" /etc/cloud/cloud.cfg.d/90-installer-network.cfg
sudo sed "s/192.168.98.201\/24/192.168.98.202\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo sed -i "s/k8s1/k8s2/" /etc/hostname
sudo systemctl reboot
# 检查主机唯一标识
ip link
sudo cat /sys/class/dmi/id/product_uuid
# sudo systemctl poweroff
# Stop-VM k8s2

# 配置k8s3 ip
Start-VM k8s3
ssh huang@192.168.98.201
sudo sed "s/192.168.98.201\/24/192.168.98.203\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo sed -i "s/k8s1/k8s3/" /etc/hostname
sudo systemctl reboot
# sudo systemctl poweroff
# Stop-VM k8s3

# 配置k8s4 ip
Start-VM k8s4
ssh huang@192.168.98.201
sudo sed "s/192.168.98.201\/24/192.168.98.204\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo sed -i "s/k8s1/k8s4/" /etc/hostname
sudo systemctl reboot
# sudo systemctl poweroff
# Stop-VM k8s4

# 配置k8s5 ip
Start-VM k8s5
ssh huang@192.168.98.201
sudo sed "s/192.168.98.201\/24/192.168.98.205\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo sed -i "s/k8s1/k8s5/" /etc/hostname
sudo systemctl reboot
# sudo systemctl poweroff
# Stop-VM k8s5
```
配置免密登录

```bash
# # ssh-keygen
# ssh-copy-id k8s1
# ssh-copy-id k8s2
# ssh-copy-id k8s3
# ssh-copy-id k8s4
# ssh-copy-id k8s5

```

# 配置控制节点(master)的高可用和负载均衡
在高可用集群中有多个控制节点(master),  需要有一个负载均衡器可以访问所有的控制节点(master), 控制节点之间会选主节点, 客户端访问kube server api时总是访问主节点。

# 配置etcd

