# 安装 doris 集群
使用官方教程安装的集群无法启动，这里先用官方方法安装集群，然后导出service和statefulset，手工安装。
## 官方k8s安装教程
注意，这里按官方k8s教程安装失败，失败原因是官方operator安装的 service/doriscluster-helm-fe-service 在启动第二个 fe pod后就无法生效， 无法通过 service/doriscluster-helm-fe-service访问到pod


## 手工安装
### 导出安装文件
```shell
./export.sh
```
### 编辑安装文件
使用replace.txt中的正则表达式替换doris.yaml中不需要的属性

因为有依赖关系， 将doris.yaml文件分别拆分为 01doris-fe.yaml 和 02doris-be.yaml 两部分分别部署

