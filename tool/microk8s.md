# microk8s配置记录
## 安装
参照 microk8s 官方安装
```shell
# 后补， 未测试
sudo snap install microk8s
```

## 修改大陆镜像地址
如果没有翻墙，启动microk8s出错，原因时启动时需要拉取registry.k8s.io上的镜像, 
修改默认镜像地址: [方法参照（Configure registry mirrors章节）](https://microk8s.io/docs/registry-private)

1. 添加镜像仓库 k8s.gcr.io：   
添加文件
/var/snap/microk8s/current/args/certs.d/k8s.gcr.io/hosts.toml 内容为 

```toml
server = "https://k8s.gcr.io"

[host."https://registry.aliyuncs.com/v2/google_containers"]
 capabilities = ["pull", "resolve"]
 override_path = true
```

2. 添加镜像仓库 registry.k8s.io：   
添加文件
/var/snap/microk8s/current/args/certs.d/registry.k8s.io/hosts.toml
```toml
server = "https://registry.k8s.io"

[host."https://registry.aliyuncs.com/v2/google_containers"]
 capabilities = ["pull", "resolve"]
 override_path = true
```

3. 修改镜像仓库 docker.io
修改文件
/var/snap/microk8s/current/args/certs.d/docker.io/hosts.toml
```toml
server = "https://docker.io"

[host."https://gi1fiwd2.mirror.aliyuncs.com"]
 capabilities = ["pull", "resolve"]
```

k8s.gcr.io 和 registry.k8s.io 是两个镜像中心， 区别在于 k8s.gcr.io 是google自己的注册中心，早期google开源时google使用了自己的注册中心， 随着发展新添加了 registry.k8s.io 注册中心， 会将负载分流到aws和google, 其实只要配置后面一个就好

## 禁用ipv6
如果是你在 windows 10 及以下 wsl 上运行则必须禁用 ipv6, 因为不支持, 非wsl宿主机则不需要

如果是 Windows11 上的 wsl 运行则需要在windows主机上的~/.wslconfig 内配置 networkingMode=mirrored, 否则也需要禁用 ipv6

microk8s正常启动，但是部署的服务需要访问apiserver时提示 https://[::1]:16443 错误。 原因是在wsl2上部署不支持wsl2，microk8s默认监听ipv6地址，并通知其他服务使用ipv6地址访问api server导致错误，修改 /var/snap/microk8s/current/args/kube-apiserver 中的配置 --bind-address=0.0.0.0 通知其他服务使用ipv4地址访问

## 启用dns插件
microk8s 默认不启动dns服务，需要安装插件， 或者通过其他方式安装 coreDns
```shell
microk8s enable dns
```

## 启用本地镜像仓库
```shell
microk8s enable registry
# 定制缓存大小
# microk8s enable registry:size=40Gi
# 查看实际部署的内容
kubectl get all -n container-registry
```

## 安装 buildah
> 测试发现 buildah 版本1.23.1在 wsl 下无法使用, apt 库上的 buildah 太旧无法更新到最新版本
microk8s 默认使用containerd 运行时管理容器, 不具备构建镜像功能 需要安装docker或这其他工具构建自定义镜像, 这里使用 buildah
```shell
apt update
# apt install buildah

apt install podman
podman build hostname/ -t localhost:32000/hostname-rest-svc:0.0.1
podman push --tls-verify=false localhost:32000/hostname-rest-svc:0.0.1

# 使用 containerd 拉下镜像
microk8s ctr i pull localhost:32000/hostname-rest-svc:0.0.1
```