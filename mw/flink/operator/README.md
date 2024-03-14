# flink-operator
```shell
# helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.7.0

# helm repo update

# helm pull flink-operator-repo/flink-kubernetes-operator --version 1.7.0

# tar -xzf flink-kubernetes-operator-1.7.0-helm.tgz

# helm template flink-operator flink-operator-repo/flink-kubernetes-operator -n mw --version 1.7.0 --include-crds > operator-1.7.0.yaml

kubectl create ns operator
helm install flink-operator flink-operator-repo/flink-kubernetes-operator -n operator --version 1.7.0
```
