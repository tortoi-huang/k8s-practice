# 安装 doris 集群

## 安装
修改 01doris-fe.yaml 中环境变量ELECT_NUMBER = 3, spec.replicas=3, 
修改 02doris-be.yaml 中 spec.replicas=3，
启动集群
```shell
kubectl apply -f 01doris-fe.yaml
# 等待be pod ready
kubectl apply -f 02doris-be.yaml

# 进入一个节点查看 frontends
kubectl exec -it pod/doriscluster-helm-fe-0 -- mysql -uroot -h127.0.0.1 -P9030 --batch -e 'show frontends;'

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

## 测试 fe master 宕机
1. master宕机，数据没有丢失
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
2. master宕机，并且master磁盘数据无法恢复

停止集群
```shell
# 删除 statefulset
kubectl delete -f 01doris-fe.yaml

# 删除 pvc
kubectl delete pvc fe-log-doriscluster-helm-fe-0
kubectl delete pvc fe-meta-doriscluster-helm-fe-0

# 重启 statefulset
kubectl apply -f 01doris-fe.yaml
```
集群启动失败,

重新删除master数据，更改为(podManagementPolicy: "Parallel")，启动成功

## 测试 be 宕机且宕机节点上数据全部丢失
1个be宕机
```shell
# 停止 statefulset
kubectl delete -f 02doris-be.yaml

# 删除 pvc
kubectl delete pvc be-log-doriscluster-helm-be-0
kubectl delete pvc be-storage-doriscluster-helm-be-0

# 重启 statefulset
```
一个be宕机 数据没有丢失

测试发现 2个(2/3)be宕机, 数据不丢失？？？



## 测试扩容 fe,be
修改 01doris-fe.yaml 中环境变量 ELECT_NUMBER=5, spec.replicas=5, 
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

## 总结
1. 集群启动，新集群首次启动需要首先启动一个节点作为master节点，命令行为
```shell
java org.apache.doris.DorisFE
```
然后启动非master节点并指向master节点, 命令行为
```shell
java org.apache.doris.DorisFE --helper $master:$edit_log_port
```
非master节点如果已经启动过一次后，下次启动需要和master节点一样的方式启动


启动后还需要在一个已经加入集群的follower节点(或master) 指向加入命令
```sql
-- 在集群中的一个节点上添加 FOLLOWER 节点, $MYSELF 是待加入节点的域名或者ip, $EDIT_LOG_PORT 是端口号默认为 9010
ALTER SYSTEM ADD FOLLOWER '$MYSELF:$EDIT_LOG_PORT';
-- ALTER SYSTEM ADD FOLLOWER 'doriscluster-helm-fe-1.doriscluster-helm-fe-internal.default.svc.cluster.local:9010';

-- 在集群中的一个节点上添加 OBSERVER 节点
ALTER SYSTEM ADD OBSERVER '$MYSELF:$EDIT_LOG_PORT';
```

2. 缺少集群感知机制，自动加入节点不稳定，如下场景可能出现问题

a. 集群增加节点或者节点数据丢失重启时，如果新节点启动暂时无法连接到集群的任意节点，会导致新节点自成集群，需要人工干预，并且不容易发现， 如果继续增加节点还出现类似问题可能会出现更多的集群

3. 不能从configmap 挂载 fe.conf， 因为启动脚本start_fe.sh 时会修改 fe.conf
4. fe 脚本进程树如下

/opt/apache-doris/fe_entrypoint.sh doriscluster-helm-fe-service
    /opt/apache-doris/fe/bin/start_fe.sh --console
        /usr/lib/jvm/java-8-openjdk-amd64/bin/java

其中 fe_entrypoint.sh 的作用是判断是否首次启动如果是则将0号节点设为 master， 并调用mysql客户端将其他节点加入master所在集群
start_fe.sh 的作用是 将fe.conf中的配置写到环境变量中, 设置CLASSPATH环境变量, 设置 JAVA_OPTS 参数