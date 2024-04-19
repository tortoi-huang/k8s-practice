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

# 查看集群管理节点， 管理节点可以有多个
kubectl exec -it tdtest-tdengine-0 -n mw -- taos -s "show mnodes"
# 查看集群数据节点
kubectl exec -it tdtest-tdengine-0 -n mw -- taos -s "show dnodes"
kubectl exec -it tdtest-tdengine-1 -n mw -- taos -s "show dnodes"
kubectl exec -it tdtest-tdengine-2 -n mw -- taos -s "show dnodes"

# 查看计算节点
kubectl exec -it tdtest-tdengine-0 -n mw -- taos -s "show qnodes"

# 查看流计算节点
kubectl exec -it tdtest-tdengine-0 -n mw -- taos -s "show snodes"
```

## 测试
进入容器执行sql
```shell
kubectl exec -it tdtest-tdengine-1 -n mw -- taos
```

```sql
-- 查看数据库
show databases;
-- 创建数据库
CREATE DATABASE power KEEP 365 DURATION 10 BUFFER 16 WAL_LEVEL 1;
-- 查看超级表
show stables;
-- 创建超级表, 超级表通常表示一个类型的设备
CREATE STABLE meters (ts timestamp, current float, voltage int, phase float) TAGS (location binary(64), groupId int);
-- 手工创建表 d1001, 普通表通常表示一个采集点的所有数据
CREATE TABLE d1001 USING meters TAGS ("California.SanFrancisco", 2);
INSERT INTO d1001 VALUES (NOW, 10.2, 219, 0.32);
-- 自动创建表, 插入一个不存在的普通表时会自动创建, 超级表必须存在, 并指定 tags
INSERT INTO d1002 USING meters TAGS ("California.SanFrancisco", 2) VALUES (NOW, 10.2, 219, 0.32);

```

## 总结
1. 所有节点通过环境变量 TAOS_FIRST_EP 注册到 master
2. 在当前版本(3.2.3.0) 的容器镜像默认通过 entrypoint 指令启动了 taosd 和 taosadapter 两个进程, 但是 没有启动 taoskeeper 的方法。 考虑改进 entrypoint 指令 shell 文件， 可以分别启动 taosd, taosadapter, taoskeeper