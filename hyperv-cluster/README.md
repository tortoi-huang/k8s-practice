# 创建kubernetes集群

## 规划
创建一个虚拟交换机

子网为 192.168.98.0/24, 网关为 192.168.98.1

创建5个虚拟机
+ ip: 192.168.98.201, hostname: k8s1 (master etcd)
+ ip: 192.168.98.202, hostname: k8s2 (master etcd)
+ ip: 192.168.98.203, hostname: k8s3 (master etcd)
+ ip: 192.168.98.204, hostname: k8s4 (node)
+ ip: 192.168.98.205, hostname: k8s5 (node)
+ ip: 192.168.98.101, 控制面板集群负载均衡 vip

虚拟机可以通过 nat 访问网络，并搭建五个节点的 kubernetes 集群。

## 宿主机配置
### 配置宿主机 ssh 访问虚拟机
复制 [config](./conf/config) 文件到宿主机用户目录 ~/.ssh/ 下

```powershell
# 看是否已经有默认的ssh 密钥，如果没有则使用生成
# ssh-keygen
# 设置脚本执行策略
# Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```
## 创建交换机
```bash
.\script\host\1k8s-init.ps1
```

## 创建虚拟机
```powershell
.\script\host\2k8s1.ps1
# 启动虚拟机
Start-VM k8s1
```
## 安装和配置虚拟机
安装时注意选择手动设置ip地址，避免安装好后无法获取ip和无法连接网络
subnet: 192.168.98.0/24
adress: 192.168.98.200
gateway: 192.168.98.1
name server: 223.5.5.5,1.1.1.1

安装用户名: huang

ubuntu软件源: http://mirrors.aliyun.com/ubuntu

### 配置ubuntu
```bash
# ssh huang@192.168.98.200

# 启用 root 账号, kubernetes 需要 root 账号运行
sudo passwd root
sudo passwd -u root 
sudo sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config -i
sudo systemctl restart ssh
logout

ssh root@192.168.98.200
apt update
apt upgrade -y

# 安装和更新 ubuntu 非常耗时, 建议此时备份虚拟磁盘模板

cd ~
git clone https://github.com/tortoi-huang/k8s-practice.git

chmod +x k8s-practice/hyperv-cluster/script/vm/*.sh
k8s-practice/hyperv-cluster/script/vm/0common-conf.sh

# 检查系统 对 cgroup v2 的支持, 输出 ： cgroup2fs
# stat -fc %T /sys/fs/cgroup/
```

## 安装软件负载均衡
创建高可用集群需要有多个节点，需要一个域名或者虚拟ip总是可以访问到其中一个存活的节点, 所以需要配置软件负载均衡, 不使用域名解析的原因是大多数操作系统和客户端会缓存域名解析的结果, 服务宕机时常常不能及时切换.

这里使用 keepalived + HAProxy 方案:
```bash
k8s-practice/hyperv-cluster/script/vm/1package-ha.sh
```

## 安装 kubernetes 及其依赖
安装 go, runc, cni, containerd
```bash
k8s-practice/hyperv-cluster/script/vm/2package-run.sh
```

### 配置 containerd 
[参考:](https://github.com/containerd/containerd/blob/main/docs/hosts.md)
生成默认的配置文件，避免的手工编写麻烦
```bash

# k8s-practice/hyperv-cluster/script/vm/3config-run-apt.sh
k8s-practice/hyperv-cluster/script/vm/3config-run.sh

# systemctl restart containerd
# 查看生效的配置
# containerd config dump

# 确认 systemdCgroup: true
# 从单独的 terminal 启动下面程序
/usr/sbin/execsnoop-bpfcc -n runc
# 然后创建容器 查看上述命令输出有没有包含systemd
ctr i pull --hosts-dir "/etc/containerd/certs.d" docker.io/library/hello-world:latest
ctr c create docker.io/library/hello-world:latest ngx
ctr t start ngx
ctr c del ngx
# ctr i del docker.io/library/nginx:1.27
```

### 安装 kubelet 及相关工具
```bash
k8s-practice/hyperv-cluster/script/vm/4package-k8s.sh

# 查看 kubelet 运行状态, 此处状态应该在不断重启中, 需要执行init或者join后才会正常运行， 也可以增加一个优先的kubelet配置让它单独运行起来, 详见使用 kubeadmin 创建 etcd 集群
sudo systemctl status kubelet
# 查看kubelet日志
# journalctl -fu kubelet

# 看起来 cgroup 管理程序没有使用 systemd ？
crictl info|grep systemd
```

## 复制虚拟机

```powershell
# 因为要复制磁盘, 使用命令stop-vm 或者在hyper-v控制台上优雅关机, 确保模板机的快照合并到虚拟磁盘, 在虚拟机内部使用linux命令关机是不会合并快照的.
.\script\host\3k8s-clone.ps1
```

### 配置各个虚拟机的ip地址
因为克隆了模板机的 ip 配置会有 ip 冲突，需要逐个虚拟机启动进行配置, 其中包含修改ip的命令执行很慢
```powershell
# 配置k8s1 ip
Start-VM k8s1
ssh root@192.168.98.200 "~/k8s-practice/hyperv-cluster/script/vm/init-node1.sh"

# k8s1 为安装工作主机, 依赖其他主机启动，最后配置
# 配置k8s2 ip
Start-VM k8s2
ssh root@192.168.98.200 "~/k8s-practice/hyperv-cluster/script/vm/init-node2.sh"
# 检查主机唯一标识
ip link
cat /sys/class/dmi/id/product_uuid

# 配置k8s3 ip
Start-VM k8s3
ssh root@192.168.98.200 "~/k8s-practice/hyperv-cluster/script/vm/init-node3.sh"

# 配置k8s4 ip
Start-VM k8s4
ssh root@192.168.98.200 "~/k8s-practice/hyperv-cluster/script/vm/init-node4.sh"

# 配置k8s5 ip
Start-VM k8s5
ssh root@192.168.98.200 "~/k8s-practice/hyperv-cluster/script/vm/init-node5.sh"

# 生成ssh key 用来使用scp 复制文件到其他节点, 非安装 kubernetes 必须
# ssh-keygen
# ssh-copy-id root@k8s2
# ssh-copy-id root@k8s3
# ssh-copy-id root@k8s4
# ssh-copy-id root@k8s5
remove-item $HOME\.ssh\known_hosts
```
宿主机配置免密登录, powershell没有ssh-copy-id 使用gitbash
```bash
# # ssh-keygen
# ssh-copy-id k8s1
# ssh-copy-id k8s2
# ssh-copy-id k8s3
# ssh-copy-id k8s4
# ssh-copy-id k8s5

```

## 配置控制节点(master)的高可用和负载均衡
在高可用集群中有多个控制节点(master),  需要有一个负载均衡器可以访问所有的控制节点(master), 控制节点之间会选主节点, 客户端访问kube server api时总是访问主节点。

### 配置 keepalived
参考: [text](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing)

keepalived 会为集群中优先级最该的服务器配置一个vip地址, 如果有更高优先级的服务器出现, keepalived 会立刻将 vip设置到更高优先级的服务器。 

其中以下变量每台服务器不一样:
+ VI_1.state: 服务器角色: MASTER 或者 BACKUP
+ VI_1.priority 优先级: 总是该数值最大的获得 vip地址
+ VI_1.unicast_src_ip 当前节点的 ip地址
+ VI_1.unicast_peer 其他节点的ip地址

其他配置解析:
* unicast_peer: 如果不配置则通过VRRP 组播发现其他节点, 如果配置了则使用该列表的ip组建集群
* unicast_src_ip: 表示可以绑定 vip的接口的ip地址, 比如 ip 192.168.98.201 绑定到 eth0 接口，backup状态下 eth0 只有一个ip就是 unicast_src_ip, master状态下 eth0 有两个 ip: unicast_src_ip 和 LOADBALANCE_VIP

在所有的 keepalived 节点 (k8s1, k8s2, k8s3) 配置健康检查服务
```bash
# 配置 keepalived
k8s-practice/hyperv-cluster/script/vm/keepalived.sh

# 查看 eth0 上的虚拟ip地址是否配置成功
ip addr
# 使用nc 确认 keepalived 健康检查发起了调用
nc -l ${APISERVER_SRC_PORT}
```

### 配置 HAProxy
分别在 k8s1, k8s2, k8s3 三个服务器上配置.  
因为 keepalived 只提供高可用能力, 不具备负载均衡能力, 所以需要配置 HAProxy 为api server做负载均衡
配置解析: 
+ APISERVER_DEST_PORT: 类似nginx 的监听端口, haproxy 对外提供服务的端口
+ server ${node-id} ${addr}:${APISERVER_SRC_PORT} 转发后端地址, 可以配置多个

```bash
k8s-practice/hyperv-cluster/script/vm/haproxy.sh
# 查看日志
journalctl -fu haproxy
# 检查端口正常监听 
lsof -i:16443
```

## 配置 etcd
通常在执行 kubeadmin init 之前 kubelet 是没有运行的, 如果需要 使用 kubeadmin 创建 etcd 集群, 则需要在 kubeadmin init 之前先将 kubelet 运行起来。这里需要配置一个更高优先级的 kubelet 服务配置文件, 在 k8s1, k8s2, k8s3上执行
```bash
mkdir /etc/systemd/system/kubelet.service.d

tee /etc/systemd/system/kubelet.service.d/kubelet.conf <<-"EOF"
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

tee /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf <<-"EOF"
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/systemd/system/kubelet.service.d/kubelet.conf
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet
```

通过脚本创建 etcd 证书, 在 k8s1 上执行
```bash
# 使用你的主机 IP 更新 HOST0、HOST1 和 HOST2 的 IP 地址
export HOST0=192.168.98.201
export HOST1=192.168.98.202
export HOST2=192.168.98.203

# 使用你的主机名更新 NAME0、NAME1 和 NAME2
export NAME0="k8s1"
export NAME1="k8s2"
export NAME2="k8s3"

# 创建临时目录来存储将被分发到其它主机上的文件
mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

kubeadm init phase certs etcd-ca

# 生成证书
kubeadm init phase certs etcd-server --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST2}/
# 清理不可重复使用的证书
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
# 不需要移动 certs 因为它们是给 HOST0 使用的

# 清理不应从此主机复制的证书
find /tmp/${HOST2} -name ca.key -type f -delete
find /tmp/${HOST1} -name ca.key -type f -delete

# 复制证书到 k8s2, k8s3
scp -r /tmp/${HOST1}/* huang@${HOST1}:
scp -r /tmp/${HOST2}/* huang@${HOST2}:
mv /tmp/${HOST0}/kubeadmcfg.yaml ~/
```

分别到 k8s2 和 k8s3 上移动文件到/etc/
```bash
chown -R root:root pki
mv pki /etc/kubernetes/
```


分别到 k8s1, k8s2, k8s3 上移动文件到/etc/
```bash
kubeadm init phase etcd local --config=$HOME/kubeadmcfg.yaml
```

## 初始化 kubernetes 集群
初始化高可用 kubernetes 集群需要设置两个参数: 
+ apiserver-advertise-address: master集群的每个节点不同, 可以访问到每个master 服务节点各自的ip地址或者域名, 在这里三个节点分别是 k8s1, k8s2, k8s3
+ control-plane-endpoint: master集群的共享ip地址或者域名, 这里是负载均衡ip ${LOADBALANCE_VIP} 或域名 cluster-endpoint

首先确保 keepalived master 是 k8s1 
### 初始化 k8s1
```bash

# 自动上传证书方式初始化
k8s-practice/hyperv-cluster/script/vm/init-k8s-upload.sh

# 如果不考虑上传证书则需要按如下方式在每个节点手工复制证书非常麻烦
# 手工复制证书脚本, 需要执行 init 后才会生成证书
# ssh-keygen
# ssh-copy-id root@k8s2
# ssh-copy-id root@k8s3

# k8s-practice/hyperv-cluster/script/vm/init-k8s-manul.sh

```

### 初始化其他控制节点 (k8s2, k8s3)
```bash
# kubeadm reset -f
# cp ~/etc/kubernetes/pki/* /etc/kubernetes/pki -r

# 将XXXXXX 替换为实际值: 
# token: 在init时会创建一个: kubeadm token list, 通常在24小时后过期, 需要重新创建: kubeadm token create --print-join-command
# discovery-token-ca-cert-hash: init时会打印, 后续可以通过命令获取: openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
kubeadm join ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --token XXXXXX \
        --discovery-token-ca-cert-hash XXXXXX \
        --control-plane
```

### 初始化数据节点 (k8s4, k8s5)
```bash
mkdir -p /etc/kubernetes/pki
kubeadm join ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --token XXXXXX \
        --discovery-token-ca-cert-hash XXXXXX \
        --control-plane
```

### 重置集群
重置到 init 或 join 之前的状态
```bash
kubeadm reset
# 如果存在，则删除
rm -rf /etc/cni/net.d
# 如果使用ipvs 则需要清除规则
ipvsadm --clear
# 清空用户配置
rm -f $HOME/.kube/config/*
```