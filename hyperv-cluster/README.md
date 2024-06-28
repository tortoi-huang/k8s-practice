# 创建kubernetes集群

## 目标
创建一个虚拟交换机

子网为 192.168.98.0/24, 网关为 192.168.98.1

创建5个虚拟机
1. ip: 192.168.98.201, hostname: k8s1
2. ip: 192.168.98.202, hostname: k8s2
3. ip: 192.168.98.203, hostname: k8s3
3. ip: 192.168.98.204, hostname: k8s4
3. ip: 192.168.98.205, hostname: k8s5

虚拟机可以通过nat访问网络，并搭建三个节点的kubernetes集群。

## 创建交换机
```bash
.\1k8s-init.ps1
```

## 创建虚拟机
```bash
.\2k8s1.ps1
```
# 安装和配置虚拟机

## 配置ubuntu
```bash
Start-VM k8s1
ssh huang@192.168.98.201

# 查看可用交换分区
swapon
# 关闭交换分区, 删除或者注释行: swap.img
sudo sed -i "s/^\/swap.img/# \/swap.img/" /etc/fstab

#配置hosts文件
sed /k8s1/d /etc/hosts -i
echo -e "\n192.168.98.201 k8s1\n192.168.98.202 k8s2\n192.168.98.203 k8s3\n192.168.98.204 k8s4\n192.168.98.205 k8s5"| sudo tee -a /etc/hosts

sudo apt update
sudo apt upgrade -y
# 重启
sudo systemctl poweroff

```

## 安装kubernetes及其依赖
```bash
# 安装containerd
# 添加docker软件源
# sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# 安装容器运行时
sudo apt install containerd.io -y
# sudo ctr i pull docker.io/library/nginx:1.27.0

# 安装kubernetes 依赖工具
sudo apt install -y apt-transport-https gpg
# 下载软件包仓库签名， 这里版本不重要，所有版本的前面都是一样的
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# 添加k8s软件仓库
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# 安装 kubelet kubeadm kubectl
sudo apt install -y kubelet kubeadm kubectl
# 标记为hold 防止自动更新
sudo apt-mark hold kubelet kubeadm kubectl

# 配置cgroup驱动，使用默认值，暂时不配置
# TODO
```

# 复制虚拟机
```bash
.\3k8s-clone.ps1
```

# 配置各个虚拟机的ip地址
```bash
# 配置k8s2 ip
Start-VM k8s2
ssh huang@192.168.98.201
# sudo sed -i "s/192.168.98.201\/24/192.168.98.202\/24/g" /etc/cloud/cloud.cfg.d/90-installer-network.cfg
sudo sed "s/192.168.98.201\/24/192.168.98.202\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo systemctl poweroff
Stop-VM k8s2

# 配置k8s3 ip
Start-VM k8s3
ssh huang@192.168.98.201
sudo sed "s/192.168.98.201\/24/192.168.98.203\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo systemctl poweroff
Stop-VM k8s3

# 配置k8s4 ip
Start-VM k8s4
ssh huang@192.168.98.201
sudo sed "s/192.168.98.201\/24/192.168.98.204\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo systemctl poweroff
Stop-VM k8s4

# 配置k8s5 ip
Start-VM k8s5
ssh huang@192.168.98.201
sudo sed "s/192.168.98.201\/24/192.168.98.205\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo systemctl poweroff
Stop-VM k8s5

```