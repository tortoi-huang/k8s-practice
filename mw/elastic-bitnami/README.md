# 安装elastic search集群
## 前提
1. 已安装ingress, 如果没有则无法通过ingress访问
## 集群架构
master节点 * 3
data 节点 * 3
coordinate 节点 * 2

## 安装 elasticsearch
```shell
# 查看部署的内容
helm template elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 --include-crds -f values-es.yaml > elasticsearch-19.17.0.yaml

# 部署master
helm install elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es.yaml
# helm upgrade elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es.yaml
# helm uninstall elasticsearch -n mw

# 验证master
kubectl run -it curl -n mw --image=curlimages/curl:8.5.0 --rm -- sh

curl -k -u elastic:Es123456 http://localhost:9200/_cat/master?v=true
curl -k -u elastic:Es123456 http://localhost:9200/_cluster/settings
curl -k -u elastic:Es123456 http://console.elasticsearch.local/_cat/master?v=true

curl -k -u elastic:Es123456 http://elasticsearch:9200/_cat/master?v=true

curl -k -u elastic:Es123456 http://elasticsearch-master-hl:9200/_cat/master?v=true
curl -k -u elastic:Es123456 http://elasticsearch-coordinating-hl:9200/_cat/master?v=true
curl -k -u elastic:Es123456 http://elasticsearch-data-hl:9200/_cat/master?v=true
```
## 安装 kibana
```shell
helm template kibana bitnami/kibana -n mw --version 10.8.0 --include-crds -f values-kb.yaml > kibana-10.8.0.yaml
helm install kibana bitnami/kibana -n mw --version 10.8.0 -f values-kb.yaml
# helm upgrade kibana bitnami/kibana -n mw --version 10.8.0 -f values-kb.yaml
# helm uninstall kibana -n mw 

curl -i http://kibana.local/

```