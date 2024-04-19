# TDEngine测试集群搭建

## 安装
使用helm搭建tdengine, tdengine 的char没有上传到hub，也没有自建repo, 手工下载安装
```shell
# 从git hub上下载 char
wget wget https://github.com/taosdata/TDengine-Operator/raw/3.0/helm/tdengine-3.0.2.tgz
tar -zxvf tdengine-3.0.2.tgz

# 到处到yaml确认安装内容
helm template tdengine-3.0.2.tgz -f values.yaml > tdengine_helm.yaml

# 手动安装pv
# kubectl apply -f pv.yaml

# 安装tdengin
kubectl apply -f tdengine.yaml -n mw
# kubectl delete -f tdengine.yaml -n mw
# kubectl delete pvc -n mw -l app.kubernetes.io/instance=tdtest

# 查看集群节点
kubectl exec -it tdtest-tdengine-0 -n mw -- taos -s "show dnodes"
kubectl exec -it tdtest-tdengine-1 -n mw -- taos -s "show dnodes"
kubectl exec -it tdtest-tdengine-2 -n mw -- taos -s "show dnodes"


```

## 总结
1. 所有节点通过环境变量 TAOS_FIRST_EP 注册到 master