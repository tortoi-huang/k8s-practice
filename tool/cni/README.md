# 测试 cni 网络

## 安装 cni 工具及插件
```bash
# 安装 cni 工具
# 下载源码，源码中 cni-1.2.3/cnitool/cnitool 是编译好的文件，直接解压出来使用, 也可以重新编译(需要先安装 go)
# wget -qO- https://mirror.ghproxy.com/https://github.com/containernetworking/cni/archive/refs/tags/v1.2.3.tar.gz| sudo tar zx -C /opt/cni/bin/ cni-1.2.3/cnitool/cnitool --strip-components=2 
wget -qO- https://github.com/containernetworking/cni/archive/refs/tags/v1.2.3.tar.gz| sudo tar zx -C /opt/cni/bin/ cni-1.2.3/cnitool/cnitool --strip-components=2 
# 从源码编译
# cd ~/cni-1.2.3/
# go mod tidy
# cd cnitool
# GOOS=linux GOARCH=amd64 go build .

ln -s /opt/cni/bin/cnitool /usr/local/bin/cnitool

# 安装 cni 网络插件
sudo mkdir -p /opt/cni/bin
wget -qO- https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz | sudo tar -C /opt/cni/bin -xvz 
echo -e "export CNI_PATH=/opt/cni/bin" | sudo tee -a /etc/profile
source /etc/profile
```

## 配置 cni
概念:
1. 一个网络空间一般称为一个容器， 
2. 一个配置(/etc/cni/net.d 中的一个文件)称为一个网络, 一个网络可以和多个网络空间(容器)关联
### 配置一个 bridge 网络
```bash
# 默认配置文件目录
sudo mkdir /etc/cni/net.d/ -p
sudo tee /etc/cni/net.d/redisnet.conf <<"EOF"
{
    "cniVersion": "0.4.0",
    "name": "redisnet",
    "type": "bridge",
    "bridge": "cni0",
    "isDefaultGateway": true,
    "forceAddress": false,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.88.0.0/16"
    }
}
EOF
# sudo rm /etc/cni/net.d/redisnet.conf
```

### 配置一个容器网络并关联到网络
```bash
# 创建一个网络命名空间(网络容器)
sudo ip netns add netns1
# sudo ip netns del netns1

# 查看网络命名空间 
ll /var/run/netns/

# 将网络命名空间(网络容器)添加到网络中: 其中 redisnet 是配置文件中的 name ; /var/run/netns/netns1 是网络命名空间, 确保配置了环境变量 CNI_PATH
sudo CNI_PATH=/opt/cni/bin cnitool add redisnet /var/run/netns/netns1
# 检查网络，正常应该没有输出
sudo CNI_PATH=/opt/cni/bin cnitool check redisnet /var/run/netns/netns1

# 查看 root 空间网络 显示多了两个网络设备 cni0 和 vethdxxxxx
ip addr
# 查看容器网络 
sudo ip -n netns1 addr
# ping 宿主机 eth0 ip
sudo ip netns exec netns1 ping XXXXX
# ping 网关
sudo ip netns exec netns1 ping 10.88.0.1
```

### 测试多个容器的网络
```bash
# 创建另一个网络命名空间 netns2
sudo ip netns add netns2
# 将网络命名空间(网络容器)添加到网络中
sudo CNI_PATH=/opt/cni/bin cnitool add redisnet /var/run/netns/netns2
# 查看 root 空间网络 显示多了一个网络设备 vethdxxxxx
ip addr
# 查看容器网络 
sudo ip -n netns2 addr
# 从 netns2 ping netns1
sudo ip netns exec netns2 ping 10.88.0.2

# 从 netns1 容器和root空间分别启动 nc 通过 netns2来访问
sudo ip netns exec netns1 nc -l 9000
sudo nc -l 9000
# 访问 netns1 的 nc
sudo ip netns exec netns2 curl http://10.88.0.2:9000
# 访问 root 的 nc
sudo ip netns exec netns2 curl http://10.88.0.1:9000
```