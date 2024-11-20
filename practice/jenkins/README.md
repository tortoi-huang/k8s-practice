# cicd 测试
git + jenkins + sonar

# helm 安装 jenkins
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