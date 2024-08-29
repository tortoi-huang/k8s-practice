# 创建kubernetes集群
本测试在阿里云(海外)ecs + ubuntu22 测试通过
## 规划
使用阿里云搭建五个ECS节点的 kubernetes 集群。使用阿里云的高可用虚拟ip替代keepalive 做高可用

## 安装和配置虚拟机

在阿里云配额中心申请 havip, 申请成功后可以在“专有网络”控制台的“高可用虚拟IP”菜单找到   

分别创建高可用虚拟ip和5个ECS，分别记录ip, 注意 havip 和 ecs 需要使用相同的交换机   
修改 https://github.com/tortoi-huang/k8s-practice.git 中 env.profile    

配置高可用“高可用虚拟IP”到虚拟机，进入“高可用虚拟IP”管理界面点击ip地址分配ecs   

### 配置ubuntu
```bash
apt update && apt upgrade -y

# 安装和更新 ubuntu 非常耗时, 建议此时备份虚拟磁盘模板

cd ~
git clone https://github.com/tortoi-huang/k8s-practice.git

chmod +x k8s-practice/cloud-vm/script/vm/*.sh
k8s-practice/cloud-vm/script/vm/0common-conf.sh
source /etc/profile

# 检查系统 对 cgroup v2 的支持, 输出 ： cgroup2fs
# stat -fc %T /sys/fs/cgroup/
```
### 分别配置每个节点
```bash
k8s-practice/cloud-vm/script/vm/init-nodeX.sh
source /etc/profile
```

## 配置控制节点(master)的高可用和负载均衡
分别在 k8s1, k8s2, k8s3 三个服务器上配置.   

### 安装软件负载均衡
云服务通常支持 keepalived 需要先在vpc界面高可用虚拟ip 或者使用负载均衡产品   
创建高可用集群需要有多个节点，需要一个域名或者虚拟ip总是可以访问到其中一个存活的节点, 所以需要配置软件负载均衡, 不使用域名解析的原因是大多数操作系统和客户端会缓存域名解析的结果, 服务宕机时常常不能及时切换.

这里使用 keepalived + HAProxy 方案:
```bash
k8s-practice/cloud-vm/script/vm/1package-ha.sh
```
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
安装 go, runc, cni, containerd
```bash
k8s-practice/cloud-vm/script/vm/2package-run.sh

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
kubectl exec -it tc1-5cffdf7c8b-6bxgc -- curl test-nginx:9030

# 测试 dns 解析
kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml

# 没问题则输出解析结果
kubectl exec -i -t dnsutils -- nslookup kubernetes.default
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