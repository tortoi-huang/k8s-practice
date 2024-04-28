# Redis
kubernetes相关技术测试
```shell
# helm pull bitnami/redis --version 19.1.3
# tar -zvxf redis-19.1.3.tgz
# 查看实际部署的yaml文件， 不包括crd定义文件，如果需要包含crd定义文件则需要添加参数  --include-crds
helm template redis-sentinel bitnami/redis --version 19.1.3 -f values.yaml -n mw > redis-sentinel-19.1.3.yaml

kubectl apply -f redis-sentinel-19.1.3.yaml -n mw
# kubectl delete -f redis-sentinel-19.1.3.yaml -n mw
# kubectl delete pvc -l app.kubernetes.io/instance=redis-sentinel -n mw

# 查看集群状态
kubectl exec -it pod/redis-sentinel-node-0 -n mw -- redis-cli --pass Redis123 info Replication
kubectl exec -it pod/redis-sentinel-node-1 -n mw -- redis-cli --pass Redis123 info Replication
```

## 总结
