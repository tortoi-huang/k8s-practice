# cicd 测试
git + jenkins + sonar

## helm 安装 jenkins
jenkins k8s上安装的容器有两部分， 一部分是 jenkins controller 处理包括 web 及对外提供接口服务， 另外一部分是 agent 主要处理流水线任务， 控制流水线运行的服务器运行流水线及流水线相关的初始化和最后清理等工作
```bash
helm repo add jenkins https://charts.jenkins.io

helm pull --version 5.7.12 jenkins/jenkins
helm template -f custom-values.yaml jenkins ./jenkins-5.7.12.tgz > template.yaml

# 提前拉取镜像防止因为拉取镜像超时导致安装失败 
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/kiwigrid/k8s-sidecar:1.28.0
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/jenkins/inbound-agent:3273.v4cfe589b_fd83-1
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/jenkins/jenkins:2.479.1-jdk17
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/bats/bats:1.11.0
# 安装 jenkins
helm install -f custom-values.yaml jenkins ./jenkins-5.7.12.tgz

# kubectl run -it curl --image=docker.io/curlimages/curl:8.5.0 --rm -- sh
```

## 安装 SonarQube
依赖 postgresql 通过配置 ConfigMap(或secrets):external-sonarqube-opts 来配置 jdbc 连接信息， 如:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: external-sonarqube-opts
data:
  SONARQUBE_JDBC_USERNAME: foo
  SONARQUBE_JDBC_URL: jdbc:postgresql://db.example.com:5432/sonar
```
然后通过 helm char value 来指定 上述 ConfigMap
```yaml
extraConfig:
  configmaps:
    - external-sonarqube-opts
```

### 安装 postgresql
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm pull --version 16.2.1 bitnami/postgresql
helm template -f postgresql-values.yaml postgresql ./postgresql-16.2.1.tgz > postgresql-template.yaml
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/bitnami/postgresql:17.1.0-debian-12-r0
# 安装 sonarqube

helm install -f postgresql-values.yaml postgresql ./postgresql-16.2.1.tgz
```
### 安装 SonarQube

```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube

helm pull --version 10.7.0+3598 sonarqube/sonarqube
helm template --include-crds -f sonarqube-values.yaml sonarqube ./sonarqube-10.7.0+3598.tgz > sonarqube-template.yaml

# 提前拉取镜像防止因为拉取镜像超时导致安装失败 
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/library/sonarqube:10.7.0-community
# 安装 sonarqube, 时间比较长
helm install --timeout 10m -f sonarqube-values.yaml sonarqube ./sonarqube-10.7.0+3598.tgz
```
安装好后使用admin登录，并将密码更改为: Sonarq@12345