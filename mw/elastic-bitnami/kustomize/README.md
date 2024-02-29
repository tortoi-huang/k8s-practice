# 安装elastic search集群
## 安装 elasticsearch

### 单节点部署
```shell
# kubectl kustomize build kustomize/overlays/single/kustomization.yaml  --enable-helm -o s.yaml
kubectl kustomize --enable-helm| kubectl apply -f -
```
