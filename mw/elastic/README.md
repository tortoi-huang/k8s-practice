# 安装elastic search集群

# 集群架构
master节点 * 3
data 节点 * 3

```shell
# 查看部署的内容
helm template elasticsearch-master elastic/elasticsearch --version 8.5.1 --include-crds -f values-master.yaml > elasticsearch-master-8.5.1.yaml
helm template elasticsearch-data elastic/elasticsearch --version 8.5.1 --include-crds -f values-data.yaml > elasticsearch-data-8.5.1.yaml

# 部署master
helm install elasticsearch-master elastic/elasticsearch --version 8.5.1 -f values-master.yaml
# helm upgrade elasticsearch-master elastic/elasticsearch --version 8.5.1 -f values-master.yaml
# helm uninstall elasticsearch-master

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