# 安装 clickhouse 集群

# 集群架构
shards * 2
replicaCount * 3

```shell
# helm pull --version 6.0.2 bitnami/clickhouse
# tar -zxvf clickhouse-6.0.2.tgz
# 查看部署的内容
helm template clickhouse-cluster bitnami/clickhouse -n mw --version 6.0.2 -f values-cluster.yaml > clickhouse-cluster-6.0.2.yaml

# 部署master
# helm install clickhouse-cluster bitnami/clickhouse -n mw --version 6.0.2 -f values-cluster.yaml
# helm upgrade clickhouse-cluster bitnami/clickhouse -n mw --version 6.0.2 -f values-cluster.yaml
# helm uninstall clickhouse-cluster

# kubectl apply -f clickhouse-cluster-6.0.2.yaml
# kubectl delete -f clickhouse-cluster-6.0.2.yaml
# kubectl delete pvc -n mw -l app.kubernetes.io/instance=clickhouse-cluster

# kubectl port-forward service/clickhouse-cluster 8123:8123 -n mw

# http://localhost:8123/play?user=clickhouse&password=Ck1234
# 连接到集群
kubectl exec -it pod/clickhouse-cluster-shard0-0 -n mw -- sh
clickhouse-client --user clickhouse --password Ck1234
```

测试
```sql
-- 查看系统信息
select * from system.clusters;

-- 创建测试数据库
CREATE DATABASE test_db0 ON CLUSTER default;
-- drop DATABASE test_db0 ON CLUSTER default sync;
-- CREATE DATABASE test_db1 ON CLUSTER cluster default ENGINE = Replicated('','','');

use test_db0;

-- 创建 MergeTree 测试标
CREATE TABLE tb_mt ON CLUSTER default (
    id VARCHAR(32), 
    part VARCHAR(32), 
    name VARCHAR(255)
) ENGINE = MergeTree() 
PRIMARY KEY (id) 
PARTITION BY part
ORDER BY id;

-- select * from tb_mt;

insert into tb_mt(id,part,name) values
('id1','a','name1'),
('id2','a','name2'),
('id3','a','name3'),
('id4','b','name4'),
('id5','b','name5'),
('id6','b','name6'),
('id7','c','name7'),
('id8','c','name8'),
('id9','c','name9')
;

-- 这里测试 replicated 2个分片到底会存到分片
CREATE TABLE tb_mt_dist ON CLUSTER default as tb_mt ENGINE = Distributed('default', 'test_db0', 'tb_mt', xxHash32(id)) ;
-- drop table tb_mt_dist ON CLUSTER default SYNC;
insert into tb_mt_dist(id,part,name) values
('id1','a','name dist 1'),
('id2','a','name dist 2'),
('id3','a','name dist 3'),
('id4','b','name dist 4'),
('id5','b','name dist 5'),
('id6','b','name dist 6'),
('id7','c','name dist 7'),
('id8','c','name dist 8'),
('id9','c','name dist 9')
;

-- 创建 MergeReplicatedMergeTreeree 测试标
CREATE TABLE tb_rmt ON CLUSTER default (
    id VARCHAR(32), 
    part VARCHAR(32), 
    name VARCHAR(255)
) ENGINE = ReplicatedMergeTree('/bitnami/clickhouse/data/data/tables/{shard}/{database}/tb_rmt', '{replica}') 
PRIMARY KEY (id) 
PARTITION BY part
ORDER BY id;

-- insert into tb_rmt(id,part,name) values
-- ('id1','a','name1'),
-- ('id2','a','name2'),
-- ('id3','a','name3'),
-- ('id4','b','name4'),
-- ('id5','b','name5'),
-- ('id6','b','name6'),
-- ('id7','c','name7'),
-- ('id8','c','name8'),
-- ('id9','c','name9')
-- ;

CREATE TABLE tb_rmt_dist ON CLUSTER default as tb_rmt ENGINE = Distributed('default', 'test_db0', 'tb_rmt', xxHash32(id)) ;
-- drop table tb_rmt_dist ON CLUSTER default SYNC;


insert into tb_rmt_dist(id,part,name) values
('id1','a','name dist 1'),
('id2','a','name dist 2'),
('id3','a','name dist 3'),
('id4','b','name dist 4'),
('id5','b','name dist 5'),
('id6','b','name dist 6'),
('id7','c','name dist 7'),
('id8','c','name dist 8'),
('id9','c','name dist 9')
;
```

## 测试结论
1. 对于 MergeTree 引擎的表， 如果直接在该表插入数据则只会在当前节点有数据
2. 对于 ReplicatedMergeTree 引擎的表， 如果直接在该表插入数据则会在当前节点和对于的replicate节点有数据， shard节点没有数据
2. 对于 Distributed 引擎的表， 如果直接在该表插入数据则会在shard节点和对于的 replicate 节点有数据，不管后端表引擎是 MergeTree 还是 ReplicatedMergeTree, 也就是Distributed 引擎赋予了 MergeTree 后端表 replicate的能力



## 问题
1. 使用 clickhouse-client 连接后 提示“history file failed”之类的错误， 这是客户端的错误， 不必理会. 或者配置clickhouse-client.xml, .yaml, .yml, .clickhouse-client/config.xml, .yaml, .yml来解决