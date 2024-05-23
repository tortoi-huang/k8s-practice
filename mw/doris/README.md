# 安装 doris 集群
使用官方教程安装的集群无法启动，这里先用官方方法安装集群，然后导出service和statefulset，手工安装。
## 官方k8s安装教程
注意，这里按官方k8s教程安装失败，失败原因是官方operator安装的 service/doriscluster-helm-fe-service 在启动第二个 fe pod后就无法生效， 无法通过 service/doriscluster-helm-fe-service访问到pod
### 安装 operator
```shell
# 安装crd
curl -O https://raw.githubusercontent.com/selectdb/doris-operator/$(curl -s  https://api.github.com/repos/selectdb/doris-operator/releases/latest | grep tag_name | cut -d '"' -f4)/config/crd/bases/doris.selectdb.com_dorisclusters.yaml

 kubectl create -f doris.selectdb.com_dorisclusters.yaml


curl -O https://raw.githubusercontent.com/selectdb/doris-operator/$(curl -s  https://api.github.com/repos/selectdb/doris-operator/releases/latest | grep tag_name | cut -d '"' -f4)/config/operator/operator.yaml

kubectl apply -f operator.yaml
```

### 安装doris
```shell
helm pull --version 1.5.2 doris-repo/doris

tar -zxvf doris-1.5.2.tgz

helm template doris-cluster doris-repo/doris -n mw --version 1.5.2  > doris-cluster-1.5.2.yaml
```

## 手工安装
参考[手动安装](./deploy/README.md "通过导出文件手动安装")