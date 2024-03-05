# cert-manager

## 安装
```shell
# install
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
```

## 概念
Issuer(crd): 抽象了一个证书颁发机构以及签名请求. 其中 ClusterIssuer 表示集群范围内的资源, Issuer 表示命名空间范围内的资源
Certificate: 证书，包括 ca根证书， 用户证书， 用户私钥
