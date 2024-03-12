# istio-practice
这里构建两个微服务测试 istio: hostname 和 proxy
通过kubernetes网关调用 proxy, proxy 调用 hostname,
hostname服务有三个版本的实例运行，v1版本有30%概率返回400，20%概率返回500； v2版本有20%概率返回400， v3版本只会返回200

## 前提环境准备
1. 安装istio, istio 安装的命名空间为 istio-system, 本测试已经使用helm安装
```shell
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl create namespace istio-system

# 这里主要是安装依赖的 crd
helm install istio-base istio/base -n istio-system --set defaultRevision=default

# 也可以不用 wait， 手工检查是否安装的组件都运行成功
helm install istiod istio/istiod -n istio-system --wait

# 查看已安装的helm程序
helm ls -n istio-system
# helm uninstall istiod -n istio-system
# helm uninstall istio-base -n istio-system
```

2. 安装第三方组件，方便观察istio网络信息，包括 grafana, tracing, prometheus, kiali
从git上下载配置，并运行
```shell
git clone https://github.com/istio/istio.git
# 切换到当前安装istio版本
# git checkout -b release-1.19 origin/release-1.19
kubectl apply -f istio/samples/addons/ -n istio-system
# kubectl delete -f istio/samples/addons/ -n istio-system
```

3. 安装网关， 网关安装的命名空间为 istio-system, 如果命名空间不是这个要修改 [路由配置文件 k8s-gateway.yaml](k8s-gateway.yaml)上引用的命名空间
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: istio-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    # 一个 Gateway.listeners 对象会占据每个node节点的一个端口号， 不同的Gateway.listeners对象要使用不同的端口
    port: 80
    protocol: HTTP
    hostname: "*.istio.lo"
    allowedRoutes:
      namespaces:
        # 允许跨命名空间
        from: All
```
3. 创建一个命名空间 tutorial, 并标记为 istio 自动注入
```shell
kubectl create namespace tutorial
kubectl leble namespace tutorial istio-injection=enabled
```

## 构建测试用的 docker镜像
```shell
# 如果不想安装docker可以安装 buildah 只有镜像管理功能，没有运行功能也没有守护进程,不需要root权限的工具
docker buildx b hostname/ -t hostname-rest-svc:0.0.1
# docker rmi hostname-rest-svc:0.0.1

docker buildx b proxy/ -t hostname-rest-proxy:0.0.1
# docker rmi hostname-rest-proxy:0.0.1
```

## 部署网关路由
为了本地测试可以使用域名访问服务，需要配置hosts文件和 kubernetes 网关路由
1. hosts 文件添加测试域名
```
127.0.0.1 grafana.istio.lo
127.0.0.1 tracing.istio.lo
127.0.0.1 prometheus.istio.lo
127.0.0.1 kiali.istio.lo
127.0.0.1 hostname.istio.lo
```
2. 添加 kubernetes网关路由,执行k8s[路由配置文件 k8s-gateway.yaml](k8s-gateway.yaml)
```shell
kubectl apply -f k8s-gateway.yaml -n tutorial
# kubectl delete -f k8s-gateway.yaml -n tutorial
```

## 部署服务
执行k8s[服务部署配置文件 k8s.yaml](k8s.yaml)
```shell
kubectl apply -f k8s.yaml -n tutorial
# kubectl delete -f k8s.yaml -n tutorial
```

## 测试观察服务
执行shell命令发起调用
```shell
# 调用 3000 次，每次间隔1秒， 输出响应码 http_code
for i in $(seq 1 3000); do curl -s -o /dev/null -w "%{http_code}\n" http://hostname.istio.lo/proxy; sleep 1; done
```
打开浏览器 登录到kiali观察调用流量情况 [kiali](http://kiali.istio.lo/kiali/console/graph/namespaces/)
打开浏览器 登录到grafana观察调用流量情况 [grafana](http://grafana.istio.lo)
打开浏览器 访问测试服务： [测试服务 http://hostname.istio.lo/proxy](http://hostname.istio.lo/proxy)

## 测试虚拟服务 (VirtualService) 和目标规则 (DestinationRule)
虚拟服务（VirtualService） 和目标规则（DestinationRule） 是 Istio 流量路由功能的核心构建模块，
目标规则(DestinationRule)可以单独使用，控制k8s service的负载均衡策略，如随机、轮询等，猜测是通过side car watch service的所有pod，将pod ip保存到side car本地，实现客户端负载均衡。
虚拟服务 (VirtualService)依赖目标规则（DestinationRule）对service pod的分组， 实现对这些分组的路由控制，比如每个分组的请求权重，灰度路由控制，其他特殊需求的路由控制。

1. 测试灰度控制，控制包含http head: end-user=jason 的请求只会路由到v3版本

```shell
kubectl apply -f istio-vs-dr.yaml -n tutorial
# kubectl delete -f istio-vs-dr.yaml -n tutorial
```
部署虚拟服务和目标规则后，执行如下命令显示后端路由一直被路由到v3版本的服务
```shell
for i in $(seq 1 3000); do curl -H "end-user: jason" http://hostname.istio.lo/proxy; sleep 1; done
# 输出一直显示是v3版本
```
如果不配置 http head: end-user=jason则会随机路由
```shell
for i in $(seq 1 3000); do curl http://hostname.istio.lo/proxy; sleep 1; done
# 输出显示随机输出
```
