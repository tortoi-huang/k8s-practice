# flink-operator
```shell
# operator 依赖 ssl 需要安装 cert-manager
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml

# helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.9.0

# helm repo update

# helm pull flink-operator-repo/flink-kubernetes-operator --version 1.9.0
# tar -xzf flink-kubernetes-operator-1.7.0-helm.tgz

# helm template flink-operator flink-operator-repo/flink-kubernetes-operator -n mw --version 1.7.0 --include-crds > operator-1.7.0.yaml

kubectl create ns operator
helm install flink-operator flink-operator-repo/flink-kubernetes-operator -n operator --version 1.9.0
```
