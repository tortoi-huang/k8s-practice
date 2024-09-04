# 创建 kubernetes 集群
本测试在阿里云(海外)ecs + ubuntu22 测试通过
## 规划
使用阿里云搭建五个ECS节点的 kubernetes 集群。使用阿里云的高可用虚拟 ip + keepalive 做高可用

## 安装和配置虚拟机

在阿里云配额中心申请 havip, 申请成功后可以在“专有网络”控制台的“高可用虚拟IP”菜单找到   

分别创建高可用虚拟 ip 和5个 ECS，分别记录 ip, 注意 havip 和 ecs 需要使用相同的交换机   
修改 https://github.com/tortoi-huang/k8s-practice.git 中 env.profile    

配置高可用“高可用虚拟IP”到虚拟机，进入“高可用虚拟IP”管理界面点击ip地址分配ecs   

### 配置 ubuntu
```bash
# 防止弹出重启服务提醒
sed "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf -i

apt update && apt upgrade -y

# 安装和更新 ubuntu 非常耗时, 建议此时备份虚拟磁盘模板

cd ~
git clone https://github.com/tortoi-huang/k8s-practice.git

chmod +x k8s-practice/cloud-vm/script/vm/*.sh
k8s-practice/cloud-vm/script/vm/0common-conf.sh

# 检查系统 对 cgroup v2 的支持, 输出 ： cgroup2fs
# stat -fc %T /sys/fs/cgroup/
```

## 配置控制节点(master)的高可用和负载均衡
分别在控制平面服务器上配置.   

### 安装软件负载均衡
云服务通常支持 keepalived 需要先在 vpc 界面高可用虚拟 ip 或者使用负载均衡产品   
创建高可用集群需要有多个节点，需要一个域名或者虚拟ip总是可以访问到其中一个存活的节点, 所以需要配置软件负载均衡, 不使用域名解析的原因是大多数操作系统和客户端会缓存域名解析的结果, 服务宕机时常常不能及时切换.

这里使用 keepalived + HAProxy 方案:

在高可用集群中有多个控制节点(master),  需要有一个负载均衡器可以访问所有的控制节点(master), 控制节点之间会选主节点, 客户端访问 kube server api 时总是访问主节点。

### 配置 keepalived
参考: [text](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing)

keepalived 会为集群中优先级最该的服务器配置一个 vip 地址, 如果有更高优先级的服务器出现, keepalived 会立刻将 vip 设置到更高优先级的服务器。 

其中以下变量每台服务器不一样:
+ VI_1.state: 服务器角色: MASTER 或者 BACKUP
+ VI_1.priority 优先级: 总是该数值最大的获得 vip 地址
+ VI_1.unicast_src_ip 当前节点的 ip地址
+ VI_1.unicast_peer 其他节点的ip地址

其他配置解析:
* unicast_peer: 如果不配置则通过 VRRP 组播发现其他节点, 如果配置了则使用该列表的ip组建集群
* unicast_src_ip: 表示可以绑定 vip 的接口的ip地址, 比如 ip 192.168.98.201 绑定到 eth0 接口，backup 状态下 eth0 只有一个ip就是 unicast_src_ip, master 状态下 eth0 有两个 ip: unicast_src_ip 和 LOADBALANCE_VIP

在所有的 keepalived 节点 (k8s1, k8s2, k8s3) 配置健康检查服务
```bash
# 配置 keepalived
k8s-practice/cloud-vm/script/vm/keepalived.sh

# 查看 eth0 上的虚拟ip地址是否配置成功
ip addr
# 使用nc 确认 keepalived 健康检查发起了调用
nc -l ${APISERVER_SRC_PORT}
```

### 配置 HAProxy 
因为 keepalived 只提供高可用能力, 不具备负载均衡能力, 所以需要配置 HAProxy 为api server做负载均衡
配置解析: 
+ APISERVER_DEST_PORT: 类似nginx 的监听端口, haproxy 对外提供服务的端口
+ server ${node-id} ${addr}:${APISERVER_SRC_PORT} 转发后端地址, 可以配置多个

```bash
k8s-practice/cloud-vm/script/vm/haproxy.sh
# 查看日志
journalctl -fu haproxy
# 检查端口正常监听 
lsof -i:16443
```

## 安装 kubernetes 及其依赖
在所有服务器上配置   
安装 go, runc, cni, containerd
```bash
k8s-practice/cloud-vm/script/vm/2package-run.sh
source /etc/profile

# 检查安装结果
ll /usr/local/sbin/runc
ll /opt/cni/bin
# 应该有containerd
ll /usr/local/bin/
systemctl status containerd
# journalctl -fu containerd
```

### 配置 containerd 
[参考:](https://github.com/containerd/containerd/blob/main/docs/hosts.md)
生成默认的配置文件，避免的手工编写麻烦
```bash

# k8s-practice/cloud-vm/script/vm/3config-run-apt.sh
k8s-practice/cloud-vm/script/vm/3config-run.sh

systemctl restart containerd
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
k8s-practice/cloud-vm/script/vm/4package-k8s.sh

# 查看 kubelet 运行状态, 此处状态应该在不断重启中, 需要执行init或者join后才会正常运行， 也可以增加一个优先的kubelet配置让它单独运行起来, 详见使用 kubeadmin 创建 etcd 集群
sudo systemctl status kubelet
# 查看kubelet日志
# journalctl -fu kubelet

# 看起来 cgroup 管理程序没有使用 systemd ？
crictl info|grep systemd
```

## 配置 etcd

## 初始化 kubernetes 集群
初始化高可用 kubernetes 集群需要设置两个参数: 
+ apiserver-advertise-address: master集群的每个节点不同, 可以访问到每个master 服务节点各自的ip地址或者域名, 在这里三个节点分别是 k8s1, k8s2, k8s3
+ control-plane-endpoint: master集群的共享ip地址或者域名, 这里是负载均衡ip ${LOADBALANCE_VIP} 或域名 cluster-endpoint

首先确保 keepalived master 是 k8s1 
### 初始化 k8s1
init 初始化会生成集群配置文件和证书 /etc/kubernetes/   
会生成初始化 kubelet 配置文件 /var/lib/kubelet/config
```bash

# 自动上传证书方式初始化
k8s-practice/cloud-vm/script/vm/init-k8s-upload.sh

# 如果不考虑上传证书则需要按如下方式在每个节点手工复制证书非常麻烦
# 手工复制证书脚本, 需要执行 init 后才会生成证书
# ssh-keygen
# ssh-copy-id root@k8s2
# ssh-copy-id root@k8s3

# k8s-practice/cloud-vm/script/vm/init-k8s-manul.sh

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
# 等待 node 和 pod 都处于ready状态, 若没有 ready请看kubelete日志
kubectl get po -n kube-system 
kubectl get node
```

### 安装 pod 容器网络
安装 helm
```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm
```
kubeadm不会安装容器网络, cni的容器插件也仅限于单机内部网络， 在安装 pod 容器网络之前 dns 不会启动, 可以通过部署一个service测试, 可以通过 service ip 访问服务，但是不能通过 service name 访问服务   
这里安装 calico 网络
```bash
helm repo add projectcalico https://docs.tigera.io/calico/charts
kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.28.1 --namespace tigera-operator
# 查看安装情况, calico-system 命名空间是 tigera-operator 创建, 如果没有这个命名空间, 或者这个命名空间没有 pod 则安装失败
kubectl get pods -n calico-system
# 检查无论以何种形式安装 calico 都会在所有节点的目录 ll /etc/cni/net.d/ 下生成两个文件: 10-calico.conflist, calico-kubeconfig, 如果没有则认为安装失败
# 这里安装失败会导致 dns 无法使用, 无法跨节点通信, 无法通过 service name 访问 pod, 各个节点的 pod ip 分配冲突

# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml
# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

```

### 初始化数据节点 (k8s4, k8s5)
```bash
mkdir -p /etc/kubernetes/pki
kubeadm join ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --token XXXXXX \
        --discovery-token-ca-cert-hash XXXXXX \
        --control-plane
```

### 部署测试应用
```bash
kubectl apply -f k8s-practice/practice/service/deploy.yaml
kubectl get po
# 进入其中一个pod 使用 curl 访问
kubectl exec -it tc1-5cffdf7c8b-cn8c7 -- curl test-nginx:9030

# 测试 dns 解析
kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml

# 没问题则输出解析结果
kubectl exec -i -t dnsutils -- nslookup kubernetes.default
```

### 重置集群
重置到 init 或 join 之前的状态
```bash
kubeadm reset -f
# 如果存在，则删除
rm -rf /etc/cni/net.d/*.conflist
# 如果使用ipvs 则需要清除规则
ipvsadm --clear
# 清空用户配置
rm -f $HOME/.kube/config
```


## 问题
+ 第一个master节点启动的时候, kubectl get node 检查节点是 noready 状态, 则应该查看 kubelet 的日志: journalctl -fu kubelet, 日志提示 Container runtime network not ready. 手工添加配置 /etc/cni/net.d/10-containerd-net.conflist 所有node 变为ready, dns pod 也变为 ready, 但是 service 名称无法访问, 部署多个pod时发现 pod ip 地址冲突。 原因是集群使用的配置 /etc/cni/net.d/10-containerd-net.conflist 为单节点配置， calico 安装失败 导致每个 node 的 pod 无法相互通信, 只能在各自 node 内部通信, 并且每个node 自行分配 ip 导致冲突

### 未解决问题
+ 无法确定 containerd 是否使用 systemd 作为 cgroup 驱动管理程序