# 安装 nginx ingress
安装 nginx ingress 默认为 deployment 安装, 该方式需要外部负载均衡器支持, 会创建一个 LoadBalancer 类型的 service 接收流量.

这里选择 daemonset 方式安装， 并开启 hostport 来接收外部流量, 
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm pull --version 4.11.3 ingress-nginx/ingress-nginx
helm template -f custom-values.yaml ingress ./ingress-nginx-4.11.3.tgz > template.yaml
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" registry.k8s.io/ingress-nginx/controller:v1.11.3
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.4
helm install -f custom-values.yaml ingress ./ingress-nginx-4.11.3.tgz
```

## 问题
+ 部署 ingress(kind: Ingress) 时应该指定 ingress class 否则会无效
+ 部署 ingress(kind: Ingress) 时，host 应该指定完整域名，而不是只设置子域名