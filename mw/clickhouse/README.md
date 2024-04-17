# 安装 clickhouse 集群

# 集群架构
master节点 * 3
data 节点 * 3

```shell
# helm pull --version 6.0.2 bitnami/clickhouse
# tar -zxvf clickhouse-6.0.2.tgz
# 查看部署的内容
helm template clickhouse-cluster bitnami/clickhouse -n mw --version 6.0.2 -f values-cluster.yaml > clickhouse-cluster-6.0.2.yaml

# 部署master
helm install clickhouse-cluster bitnami/clickhouse -n mw --version 6.0.2 -f values-cluster.yaml
# helm upgrade clickhouse-cluster bitnami/clickhouse -n mw --version 6.0.2 -f values-cluster.yaml
# helm uninstall clickhouse-cluster

# 验证master
curl -k -u elastic:es123456 https://localhost:9200/_cat/master?v=true
curl -k -u elastic:es123456 https://localhost:9200/_cluster/settings
curl -k -u elastic:es123456 https://console.elasticsearch.local/_cat/master?v=true --insecure
curl -k -u elastic:es123456 https://elasticsearch-master:9200/_cat/master?v=true --insecure

# 部署data
helm install elasticsearch-data elastic/elasticsearch --version 8.5.1 -f values-data.yaml
# helm upgrade elasticsearch-data elastic/elasticsearch --version 8.5.1 -f values-data.yaml
# helm uninstall elasticsearch-master


# 部署kibana 失败！ 原因是官方的kibanna char必须依赖es 的tls证书， 前面els没有部署tls， 这里就进行不下去了
helm pull elastic/kibana --version 8.5.1
helm template kibana elastic/kibana --version 8.5.1 --include-crds -f values-kibana.yaml > kibana-8.5.1.yaml
helm install kibana elastic/kibana --version 8.5.1 -f values-kibana.yaml

```