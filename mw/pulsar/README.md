# pulsar
kubernetes相关技术测试
```shell
# 查看实际部署的yaml文件， 不包括crd定义文件，如果需要包含crd定义文件则需要添加参数  --include-crds
helm template pulsar-cluster apache/pulsar -f values.yaml > pulsar-3.0.0.yaml

# 使用helm安装, 安装后在本地显示名称为 pulsar-cluster
helm install pulsar-cluster apache/pulsar -f values.yaml

# helm uninstall pulsar-cluster
```