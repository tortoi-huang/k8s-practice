# TDEngine测试集群搭建
使用helm搭建tdengine, tdengine 的char没有上传到hub，也没有自建repo, 手工下载安装
```shell
# 从git hub上下载 char
wget wget https://github.com/taosdata/TDengine-Operator/raw/3.0/helm/tdengine-3.0.2.tgz

# 到处到yaml确认安装内容
helm template tdengine-3.0.2.tgz > tdengine.yaml --set storage.className=hostpath

# 安装pv
kubectl apply -f pv.yaml

# 安装tdengin
kubectl apply -f tdengine.yaml
```