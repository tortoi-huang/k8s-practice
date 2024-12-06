# cicd 测试
git + jenkins + sonar,
其中 git 使用 bitbucket 云服务替代, 这里不做安装

## 安装镜像仓库
这里直接使用 microk8s 的 registry, 启用后会在集群内部访问地址为 registry.container-registry; 在 k8s node 节点访问地址为 localhost:32000
```bash
sudo microk8s enable registry
```

## 安装 postgresql
sonarqube 依赖 postgresql
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm pull --version 16.2.1 bitnami/postgresql
helm template -f postgresql-values.yaml postgresql ./postgresql-16.2.1.tgz > postgresql-template.yaml
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/bitnami/postgresql:17.1.0-debian-12-r0
# 安装 sonarqube

helm install -f postgresql-values.yaml postgresql ./postgresql-16.2.1.tgz
# helm upgrade -f postgresql-values.yaml postgresql ./postgresql-16.2.1.tgz
```
## 安装 git 代码管理工具
这里配置一个 cloud bitbucket 实现
### 配置 bitbucket
bitbucket 没有开源版本, 这里使用 bitbucket cloud
+ 新建上传一个 Java 项目
+ [创建 app password](#bitbucket_secret) 登录 bitbucket , 进入菜单: Settings/Personal Bitbucket settings/, 在左侧菜单 Account Setting 配置 username, 在 App passwords 设置应用密码, 这个用户名和密码后面提供给 sonarqube 和 jenkins 拉取代码, 拉取形式如 https://${username}:${password}@url
+ [创建 access token](#bitbucket_token) 登录 bitbucket , 进入需要访问的 repository, 在左侧菜单 Repository settings > Access tokens 点击 Create Repository Access Token 创建一个 token 可以使用如 https://x-token-auth:${token}@url 方式访问

### gitlab
TODO 这枚没有安装成功, 原因是 gitlab chart 依赖太复杂, 短期没有理清
```bash
helm repo add atlassian-data-center https://atlassian.github.io/data-center-helm-charts

helm pull --version 8.6.0 gitlab/gitlab
helm template -f gitlab-values.yaml gitlab ./gitlab-8.6.0.tgz > gitlab-template.yaml
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/bitnami/postgresql:17.1.0-debian-12-r0
# 安装 sonarqube

helm install -f postgresql-values.yaml postgresql ./postgresql-16.2.1.tgz

```
### bitbucket
TODO 这枚没有安装成功, 原因是没有开源或者免费版本 chart 只有使用版本
```bash
helm repo add atlassian-data-center https://atlassian.github.io/data-center-helm-charts

helm pull --version 1.22.0 atlassian-data-center/bitbucket
helm template -f bitbucket-values.yaml bitbucket ./bitbucket-1.22.0.tgz > bitbucket-template.yaml
# 安装 bitbucket

helm install -f bitbucket-values.yaml bitbucket ./bitbucket-1.22.0.tgz

```

## 安装 SonarQube
依赖 postgresql 通过配置 ConfigMap(或 secrets):external-sonarqube-opts 来配置 jdbc 连接信息, 如:
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
### 安装 SonarQube

```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube

helm pull --version 10.7.0+3598 sonarqube/sonarqube
helm template --include-crds -f sonarqube-values.yaml sonarqube ./sonarqube-10.7.0+3598.tgz > sonarqube-template.yaml

# 提前拉取镜像防止因为拉取镜像超时导致安装失败 
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/library/sonarqube:10.7.0-community
# 安装 sonarqube, 时间比较长
helm install --timeout 10m -f sonarqube-values.yaml sonarqube ./sonarqube-10.7.0+3598.tgz
# helm upgrade --timeout 10m -f sonarqube-values.yaml sonarqube ./sonarqube-10.7.0+3598.tgz
```
### 配置 SonarQube
+ 安装好后首次使用使用 admin 登录要求更改密码, 并将密码更改为: Sonarq@12345
+ 登录后进入 administration/marketplace 安装插件, 因为大部分插件都需要从 github 下载, 所以可能安装失败。可以先下载到指定目录 /opt/sonarqube/extensions/plugins/ 。 如果使用 microk8s-hostpath 存储, 可以通过 kubectl get pv pvc-xxxx -o yaml 查看本地挂载的目录, 往里面复制文件后重启即可. 下面直接进入容器内部下载后重启
```sh
# 进入容器
kubectl exec -it pod/sonarqube-sonarqube-0 -- sh
mkidr /opt/sonarqube/extensions/plugins
cd /opt/sonarqube/extensions/plugins
# checkstyle 插件
wget https://mirror.ghproxy.com/https://github.com/checkstyle/sonar-checkstyle/releases/download/10.20.1/checkstyle-sonar-plugin-10.20.1.jar
# findbugs 插件
# wget https://repo.maven.apache.org/maven2/com/github/spotbugs/sonar-findbugs-plugin/4.3.0/sonar-findbugs-plugin-4.3.0.jar
wget https://maven.aliyun.com/repository/public/com/github/spotbugs/sonar-findbugs-plugin/4.3.0/sonar-findbugs-plugin-4.3.0.jar
# mybatis 插件
wget https://mirror.ghproxy.com/https://github.com/donhui/sonar-mybatis/releases/download/1.0.8/sonar-mybatis-plugin-1.0.8.jar
# dependency 插件
wget https://mirror.ghproxy.com/https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/5.0.0/sonar-dependency-check-plugin-5.0.0.jar

# 退出容器
exit
kubectl rollout restart statefulset.apps/sonarqube-sonarqube
```
+ 创建项目: 进入 projects/create project/import from other DevOps Platforms/import from bitbutcket cloud/ 填写 bitbutcket 相关信息及<a id="bitbucket_secret">bitbutcket 密钥</a>, 然后选择项目
+ [创建 sonarqube 密钥](#sonar_secret): 登录/my account/Administrator/security/Generate Tokens 生成一个密钥, 后续提供给 jenkins 访问

## helm 安装 jenkins
jenkins k8s 上安装的容器有两部分, 一部分是 jenkins controller 处理包括 web 及对外提供接口服务, 另外一部分是 agent 主要处理流水线任务, 控制流水线运行的服务器运行流水线及流水线相关的初始化和最后清理等工作
```bash
helm repo add jenkins https://charts.jenkins.io

helm pull --version 5.7.16 jenkins/jenkins
helm template -f jenkins-values.yaml jenkins ./jenkins-5.7.16.tgz > jenkins-template.yaml

# 提前拉取镜像防止因为拉取镜像超时导致安装失败 
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/kiwigrid/k8s-sidecar:1.28.0
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/jenkins/inbound-agent:3273.v4cfe589b_fd83-1
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/jenkins/jenkins:2.479.2-jdk17
# ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/bats/bats:1.11.0
# 安装 jenkins
helm install -f jenkins-values.yaml jenkins ./jenkins-5.7.16.tgz
# helm upgrade -f jenkins-values.yaml jenkins ./jenkins-5.7.16.tgz

# kubectl run -it curl --image=docker.io/curlimages/curl:8.5.0 --rm -- sh
```
### 配置 jenkins 
```bash
# 配置流水线
ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/library/gradle:8.11.1-jdk17
ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/moby/buildkit:master-rootless
ctr i pull --hosts-dir "/var/snap/microk8s/current/args/certs.d" docker.io/bitnami/kubectl:latest

# 配置 buildkit 镜像仓库等信息
kubectl apply -f config.yaml
```

+ 在 Dashboard/Manage Jenkins/Credentials/System/Global credentials (unrestricted)下添加 <a id="bitbucket_secret">bitbutcket 密码</a> 格式为 Username with password id 为 bk_app
+ 在 Dashboard/Manage Jenkins/Credentials/System/Global credentials (unrestricted)下添加 <a id="bitbucket_token">bitbutcket token</a> 格式为 Secret text id 为 bb_token 
+ 在 Dashboard/Manage Jenkins/Credentials/System/Global credentials (unrestricted)下添加 <a id="sonar_secret">sonarqube 密钥</a> 

### 问题
1. jenkins 没法进入容器, 提示 running Jenkins temporarily with -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true might make the problem clearer, 在环境变量 JAVA_OPTS 添加 -Dcasc.reload.token=$(POD_NAME) -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true 查看更详细日志
2. 有些容器执行命令提示权限不足, pod 的 spec 下增加如下权限使得所有容器都用同一用户解决：
```yaml
kind: Pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
```
3. buildkit 无法拉取镜像基础镜像, 通过进入容器(或检查 dockerfile 定义) 确定容器用户为 user, 通过 config.yaml 中的的 configmap 挂载到用户目录 /home/user/.config/buildkit/ 解决。 

#### 关于用户和权限
1. 挂载目录和文件 owner:group 是 root:root, 挂载时可以指定读写执行权限, 如 /home/jenkins/agent 就是挂载目录归属于 root 并指定权限为777
2. 用户名和 ID: 如果在构建镜像的 dockerfile 中 user 指定了一个非整数的值, 则用户名是该值, 用户 id 自动生成, 通常是1000, 有用户目录, 如果指定的 是一个整数值, 默认用户 id 是该值, 没有用户名, 也没有用户目录(用户目录是/), 如果 pod.spec 或者 pod.spec.container 中指定了 runAsUser 和 runAsGroup 则覆盖 dockerfile 中的定义
3. 不同容器用户创建的目录权限: 根据 id 而不是用户名判断一个文件的用户和组, 如在 gradle 容器使用用户 gradle(id:1000) 用户创建的文件, 挂载到 buildkit 容器, 该容器的用户 user(id:1000) 看到这些文件是自己创建的。对于没有定义用户名(通常是 dockerfile 中 user 指定为整数),则文件归属显示用户 id, 如 bitnami/kubectl 容器, 它的 dockerfile 指定了 user=1001, 启动容器时指定了 runAsUser: 1000, 则其中挂载的其他容器 gradle(id:1000) 用户创建的文件归属都显示为 1000
