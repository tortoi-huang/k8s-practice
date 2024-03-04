# mongodb-shared
搭建 mongodb集群: 2副本, 2分片, 1个路由节点(mongos), 0个仲裁节点, 1个config server
副本: 数据备份数量
分片: 数据被hash打散存储的分区数量
路由节点: 将请求路由到各个主分片
仲裁节点: 参与选主投票，不能当选，不存储数据
config server: 

# 搭建集群
```shell
# helm pull bitnami/mongodb-sharded --version 7.8.1
# tar -xzf mongodb-sharded-7.8.1.tgz
# cp mongodb-sharded/values.yaml simple.yaml

helm template mongodb bitnami/mongodb-sharded -n mw --version 7.8.1 --include-crds --values simple.yaml > mongodb-sharded-7.8.1.yaml

kubectl -n mw apply -f mongodb-sharded-7.8.1.yaml

# 部署chart2db访问
kubectl -n mw apply -f chat2db.yaml
# kubectl port-forward service/chat2db 10824:chat2db -n mw
```