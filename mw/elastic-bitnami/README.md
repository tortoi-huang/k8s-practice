# 安装elastic search集群
## 前提
1. 已安装ingress, 如果没有则无法通过ingress访问
## 集群架构
master节点 * 3
data 节点 * 3
coordinate 节点 * 2

## 安装 elasticsearch

### 单节点部署
```shell
# 单节点部署
helm template elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es-single.yaml > elasticsearch-single-19.17.0.yaml
kubectl -n mw apply -f elasticsearch-single-19.17.0.yaml
# helm install elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es-single.yaml
# helm upgrade elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es-single.yaml
```

### 验证
```shell
# 验证master
kubectl run -it curl -n mw --image=curlimages/curl:8.5.0 --rm -- sh

curl -k -u elastic:Es123456 https://localhost:9200/_cat/master?v=true
curl -k -u elastic:Es123456 https://localhost:9200/_cluster/settings
# curl -k -u elastic:Es123456 https://console.elasticsearch.local/_cat/master?v=true

curl -k -u elastic:Es123456 https://elasticsearch:9200/_cat/master?v=true

curl -k -u elastic:Es123456 https://elasticsearch-master-hl:9200/_cat/master?v=true
curl -k -u elastic:Es123456 https://elasticsearch-coordinating-hl:9200/_cat/master?v=true
curl -k -u elastic:Es123456 https://elasticsearch-data-hl:9200/_cat/master?v=true
```

### 多节点部署
```shell
# 查看部署的内容
helm template elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es.yaml > elasticsearch-19.17.0.yaml

# 部署master
kubectl -n mw apply -f elasticsearch-19.17.0.yaml
# helm install elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es.yaml
# helm upgrade elasticsearch bitnami/elasticsearch -n mw --version 19.17.0 -f values-es.yaml
# helm uninstall elasticsearch -n mw
```


## 安装 kibana
```shell
helm template kibana bitnami/kibana -n mw --version 10.8.0 -f values-kb.yaml > kibana-10.8.0.yaml
# helm install kibana bitnami/kibana -n mw --version 10.8.0 -f values-kb.yaml
kubectl -n mw apply -f kibana-10.8.0.yaml
# helm upgrade kibana bitnami/kibana -n mw --version 10.8.0 -f values-kb.yaml
# helm uninstall kibana -n mw 

curl -i http://kibana.local/

```

## 问题
1. tls问题，部署无tls认证的elastic集群， 启动kibana integrations 提示无法连接elasticsearch xpack feet没有启用。 将elasticsearch 启用tls解决。
2. elasticsearch启用 tls后怎么配置ingress， 未解决
3. 