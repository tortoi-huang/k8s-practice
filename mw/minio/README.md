# minio
本实例通过microk8s调试成功，通过docker-desktop 的kubenetes调试失败。原因是docker-desktop的pv总是出现权限问题，一直没法处理

## 配置 minio
### 存储
这里使用 microk8s 默认的存储类 microk8s-hostpath，该存储类会在 宿主机目录 /var/snap/microk8s/common/default-storage/ 下去创建 hostpath pv存储目录。
这个依赖 microk8s hostpath插件， 使用命令启动 
```shell
microk8s enable hostpath-storage
```

### helm 安装参数
从char包中获取配置的 value.yaml, 避免手工重新编写麻烦
```shell
# 查看有没有bitnami的仓库， 没有则需要先添加
helm repo list
# 添加bitnami的仓库
helm repo add bitnami https://charts.bitnami.com/bitnami

# 下载char包
# helm pull bitnami/minio  --version 12.13.2
# tar -zvxf minio-12.13.2.tgz minio/values.yaml
# mv minio/values.yaml minio/values_simple.yaml
```
修改values.yaml配置


### helm 安装
```shell
# 查看实际部署的yaml文件， 不包括crd定义文件，如果需要包含crd定义文件则需要添加参数  --include-crds
helm template minio-cluster bitnami/minio --version 12.13.2 --include-crds -f minio/values_simple.yaml > minio-12.13.2.yaml


# 避免拉取镜像问题导致安装失败
#  microk8s ctr i pull docker.io/bitnami/minio:2023.12.23-debian-11-r3
# 使用helm安装, 安装后在本地显示名称为 minio-cluster
# helm install minio-cluster bitnami/minio --version 12.13.2 -f minio/values_simple.yaml
kubectl apply -f minio-12.13.2.yaml

# 安装后更新
# helm upgrade minio-cluster bitnami/minio --version 12.13.2 --reuse-values -f minio/values_simple.yaml

# helm uninstall minio-cluster
kubectl delete -f minio-12.13.2.yaml
```

## ingress
ingress 以及service 服务依赖dns，确保安装了dns
```shell
# 没有安装dns会导致无法访问ingress
# microk8s enable dns
microk8s enable ingress

# 测试登录, 如果是 wsl 要将ip换成宿主机的ip
curl -X POST -i 'http://console.minio.local/api/v1/login' -H "Content-Type: application/json" --data-raw '{"accessKey":"admin","secretKey":"admin123"}' --resolve console.minio.local:80:127.0.0.1
# 测试 prometheus 指标, 如果是 wsl 要将ip换成宿主机的ip
curl -i 'http://api.minio.local/minio/v2/metrics/cluster' --resolve console.minio.local:80:127.0.0.1
```

## 安装 prometheus
prometheus 非必选项， 但是方便监控minio集群
参考 ../prometheus 安装 prometheus-operator 和 prometheus


## 清理


## 问题
1. 无法启动，通过kubectl describe pod/minio-cluster-1 发现原因是没有安装dns, 使用 microk8s enable dns 安装coreDns解决。
2. 无法通过9001端口访问：
```shell
# debug 调试, --target 表示需要调试的目标容器，必须设置，否则可以启动，但是debug容器会独立运行，无法调试
kubectl debug -it minio-cluster-0 --image=curlimages/curl --target=minio
# 会打印debug容器信息，并进入调试状态
# 退出后可以在此进入调试容器
kubectl exec -it minio-cluster-0 -c debug_container_id -- sh
```
netstat -l -t -p
发现9001端口没有启动监听，断定是启动参数配置错误
3. ingress无法通过 http://localhost 或者127.0.0.1 访问, 研究发现部署环境是wsl, 可以在wsl 上使用 curl http://localhost 访问，但是不能在windows宿主机上访问 http://localhost， 在windows上改用wsl的ip访问即可

4. 启动提示 returned drive not found (*fmt.wrapError)