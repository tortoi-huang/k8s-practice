# 安装 doris 集群

## 安装
修改 01doris-fe.yaml 中环境变量ELECT_NUMBER = 3, spec.replicas=3, 
修改 02doris-be.yaml 中 spec.replicas=3，
启动集群
```shell
kubectl apply -f 01doris-fe.yaml
# 等待be pod ready
kubectl apply -f 02doris-be.yaml

# 进入一个节点操作数据
kubectl exec -it pod/doriscluster-helm-fe-0 -- mysql -uroot -h127.0.0.1 -P9030
# 执行 test.sql中的sql插入数据
```

## 测试down机重启
```shell
kubectl delete -f 02doris-be.yaml
kubectl delete -f 01doris-fe.yaml
# 等待关闭
kubectl get all

kubectl apply -f 01doris-fe.yaml
# 等待be pod ready
kubectl apply -f 02doris-be.yaml
# 进入一个节点检查数据没有丢失
```

## 的是master宕机
进入mysql 界面查看master节点
```sql
show frontends;
```
加入看到的master节点是 kubectl delete pod/doriscluster-helm-fe-0
然后使用 kubectl delete pod/doriscluster-helm-fe-0 删除对应节点
重新查看master节点
```sql
show frontends;
```
这里可能会发生异常: ForwardToMasterException, 
需要等待选举完成后再次查看，发现master节点变更

## 测试扩容 fe,be
修改 01doris-fe.yaml 中环境变量ELECT_NUMBER = 5, spec.replicas=5, 
修改 02doris-be.yaml 中 spec.replicas=5，
更新集群
```shell
kubectl apply -f 01doris-fe.yaml

kubectl apply -f 02doris-be.yaml
```
使用 show frontends; 和show backends; 检查集群扩容成功, 检查数据无丢失

## 测试缩容 fe, be
缩容前插入测试数据 test2.sql

修改 01doris-fe.yaml 中环境变量ELECT_NUMBER = 3, spec.replicas=3, 更新集群
```shell
# fe需要选举, 扩容缩容需要全部停止后 全部重建 
kubectl delete -f 01doris-fe.yaml
kubectl apply -f 01doris-fe.yaml

# 检查数据没有丢失
# select * from session_data order by visitorid;
```

修改 02doris-be.yaml 中 spec.replicas=3，更新集群
```shell
# kubectl delete -f 02doris-be.yaml
kubectl apply -f 02doris-be.yaml

# 登录fe 查看 be状态，显示还是有5个节点， 两个无法连接
# show backends;
# 检查数据没有丢失
# select * from session_data order by visitorid;
```

优雅删除 be
先从系统删除节点
```sql
-- 以下删除为异步操作， 许等待
ALTER SYSTEM DECOMMISSION BACKEND "doriscluster-helm-be-4.doriscluster-helm-be-internal.default.svc.cluster.local:9050";
ALTER SYSTEM DECOMMISSION BACKEND "doriscluster-helm-be-3.doriscluster-helm-be-internal.default.svc.cluster.local:9050";

-- 查看是否已经删除完成
show backends;
```
系统删除完成后执行kubernetes 缩容,
修改 02doris-be.yaml 中 spec.replicas=3，更新集群