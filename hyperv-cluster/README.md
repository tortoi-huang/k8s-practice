# 创建kubernetes集群

## 规划
创建一个虚拟交换机

子网为 192.168.98.0/24, 网关为 192.168.98.1

创建5个虚拟机
1. ip: 192.168.98.201, hostname: k8s1 (node)
2. ip: 192.168.98.202, hostname: k8s2 (master etcd node)
3. ip: 192.168.98.203, hostname: k8s3 (master etcd node)
3. ip: 192.168.98.204, hostname: k8s4 (master etcd node)
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
sed /k8s1/d /etc/hosts -i
echo -e "\n192.168.98.201 k8s1\n192.168.98.202 k8s2\n192.168.98.203 k8s3\n192.168.98.204 k8s4\n192.168.98.205 k8s5"| sudo tee -a /etc/hosts

sudo apt update
sudo apt upgrade -y
# 重启
sudo systemctl poweroff

```

## 安装kubernetes及其依赖
```bash
sudo mkdir /usr/local/lib/systemd/system -p
sudo curl -o /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
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
# 启动cni网络支持, 如果不启动此项则后续 kubelet服务会启动失败，并一直重启
sudo sed -i -r "s/^(disabled_plugins)/# \1/g" /etc/containerd/config.toml
sudo systemctl restart containerd

# 查看 containerd 运行状态
sudo systemctl status containerd

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

# 查看 kubelet 运行状态
sudo systemctl status kubelet
# 查看kubelet日志
# journalctl -fu kubelet

# 配置cgroup驱动，使用默认值，暂时不配置
# TODO

# 配置 kubelet
sudo tee /etc/systemd/system/kubelet.service.d/kubelet.conf <<EOF
# 将下面的 "systemd" 替换为你的容器运行时所使用的 cgroup 驱动。
# kubelet 的默认值为 "cgroupfs"。
# 如果需要的话，将 "containerRuntimeEndpoint" 的值替换为一个不同的容器运行时。
#
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: false
authorization:
  mode: AlwaysAllow
cgroupDriver: systemd
address: 127.0.0.1
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
staticPodPath: /etc/kubernetes/manifests
EOF

sudo systemctl daemon-reload
sudo systemctl restart kubelet
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

为了不不然模板机， 我们使用 k8s2 作为配置操作的主机, 登录到 k8s2

ssh k8s2

```bash
ssh-keygen
ssh-copy-id k8s1
ssh-copy-id k8s3
ssh-copy-id k8s4
ssh-copy-id k8s5

```

# 配置etcd

分别登录 k8s2执行以下命令
```bash
# 配置 k8s2 ip
sudo tee /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/systemd/system/kubelet.service.d/kubelet.conf
Restart=always
EOF

ssh k8s3
sudo tee /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/systemd/system/kubelet.service.d/kubelet.conf
Restart=always
EOF
exit

ssh k8s4
sudo tee /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/systemd/system/kubelet.service.d/kubelet.conf
Restart=always
EOF
exit

```