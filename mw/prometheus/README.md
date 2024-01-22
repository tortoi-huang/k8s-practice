# prometheus
参照官网安装prometheus-operator 并安装 prometheus 实例。
这里使用官网的实例 https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
因为使用了集群资源到命名空间资源的绑定， 需要在yaml中写死命名空间，这里将官网的实例的命名空间default更改到operator

安装operator:
```shell
# apply命令会提示文件太大无法执行
kubectl create -f bundle.yaml

kubectl get all -n prometheus
```

安装 prometheus
```shell
kubectl create ns pth
kubectl apply -f prometheus.yaml -n pth

# 测试 依赖ingress 已安装
kubectl apply -f ingress.yaml -n pth

curl -i 'http://console.prometheus.local' -H "Content-Type: application/json" --resolve console.prometheus.local:80:127.0.0.1
```

## 问题
1. 部署 ServiceMonitor 资源后无法监控， 原因是默认情况下 Prometheus会监控它所在的命名空间的 ServiceMonitor 资源， 部署在其他命名空间不会监控，如果需要监控则需要修改 prometheus.yaml 的 serviceMonitorNamespaceSelector 熟悉（未测试）, 将 ServiceMonitor 资源部署到和Prometheus同一个命名空间即可, ServiceMonitor可以指向其他命名空间