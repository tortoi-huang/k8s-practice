
# 安装
使用helm生成yaml文件使用 kubectl安装。
```shell
# helm pull bitnami/vault --version 0.10.2
# tar -xzf vault-0.10.2.tgz
# cp vault/values.yaml values.yaml
helm template vault bitnami/vault -n mw --version 0.10.2 --include-crds --values helm-vault-raft-values.yaml > helm-vault-raft-values-0.10.2.yaml

kubectl apply -f helm-vault-raft-values-0.10.2.yaml
# helm install vault hashicorp/vault -n mw --version 0.10.2 --values helm-vault-raft-values.yaml
```

# 初始化
vault刚安装好是不能使用的，pod 状态不为 ready， 需要初始化。
原因是vaul需要生成加密暑假的密钥, 称为share key, 另外这些密钥和数据存储在一起，通过一个 root key(root token) 加密， root key也是存储在磁盘上的，但是不会和share key一起存放， root key是使用 share key加密存储的(Shamir's secret sharing)。
服务初始化会生成几个 share key 和一个 root key, 并加密保存起来。

服务启动(重启)时需要提供一定数量(Threshold)的 share key 来解密 root key 才能完成启动。 这个动作称为unseal. 
对于google, aws 等大型云厂商集群提供了可靠的密钥存储服务(KMS)，可以用来保存这些share key, 可以使用 Auto unseal功能， 自建的 kubernetes集群还不支持(vault的作用本来就是kms, 有kms还要部署vault干啥?)。

以下通过shell 命令生成 实际也可以通过 首次访问ui时通过ui界面操作: http://localhost:8200/ui
```shell
# 这段shell代码可以通过执行 init_vault.sh 完胜
# 初始化生成节点的 share key 和 root key, 集群的每个节点都要单独初始化
kubectl exec -it pod/vault-0 -n mw -- vault operator init
# Unseal Key 1: +9rLJ3FkrfjXMJLHR+5HH3ZtkOD75yMcLFDzWNsykZ/1
# Unseal Key 2: tKg8y1mLoleBRBnQgBio3LhmxFTG2F1ijqHA1dF8UXdb
# Unseal Key 3: 7cINoLezc1tAie5sLnNvtAxrDvbdviZEagAOZHDq0NMM
# Unseal Key 4: rfm/FMh12qQw1G+pNSgpCLz++m4xKSK1tGTKpnKG7z6Y
# Unseal Key 5: aJn8HfF7fBJIe8OeAWACWG9TF72V+UhnX24jpmJT08Dk

# Initial Root Token: hvs.ntooV7oj4iUiWCP7FM3xCqT3

# 每次启动需要提供至少3个share key 来解封节点，其实时解密 root key
kubectl exec -it pod/vault-0 -n mw -- vault operator unseal  +9rLJ3FkrfjXMJLHR+5HH3ZtkOD75yMcLFDzWNsykZ/1
kubectl exec -it pod/vault-0 -n mw -- vault operator unseal  tKg8y1mLoleBRBnQgBio3LhmxFTG2F1ijqHA1dF8UXdb
kubectl exec -it pod/vault-0 -n mw -- vault operator unseal  7cINoLezc1tAie5sLnNvtAxrDvbdviZEagAOZHDq0NMM

kubectl exec -it pod/vault-1 -n mw -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -it pod/vault-1 -n mw -- vault operator unseal  +9rLJ3FkrfjXMJLHR+5HH3ZtkOD75yMcLFDzWNsykZ/1
kubectl exec -it pod/vault-1 -n mw -- vault operator unseal  tKg8y1mLoleBRBnQgBio3LhmxFTG2F1ijqHA1dF8UXdb
kubectl exec -it pod/vault-1 -n mw -- vault operator unseal  7cINoLezc1tAie5sLnNvtAxrDvbdviZEagAOZHDq0NMM

kubectl exec -it pod/vault-2 -n mw -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -it pod/vault-2 -n mw -- vault operator unseal  +9rLJ3FkrfjXMJLHR+5HH3ZtkOD75yMcLFDzWNsykZ/1
kubectl exec -it pod/vault-2 -n mw -- vault operator unseal  tKg8y1mLoleBRBnQgBio3LhmxFTG2F1ijqHA1dF8UXdb
kubectl exec -it pod/vault-2 -n mw -- vault operator unseal  7cINoLezc1tAie5sLnNvtAxrDvbdviZEagAOZHDq0NMM
```

# 访问web UI
```shell
# 代理服务地址，随机路由到后端pod
kubectl port-forward service/vault 8200:http -n mw
```
## 首次登录
首次登录需要用 root key(root token) 登录
### 创建用户
使用pod的root token登录，进入 dashboard界面， 进入 access/Authentication Methods: 点击"Enable new Method"功能添加认证方式，这里选择 username & password模式新建名为为userpass，保存后回到 access/Authentication Methods 界面，点击新的userpass 行，添加用户


# 问题
1. pod启动后是如何知道vault集群的其他节点的？ 通过配置文件中的 service_registration配置决定如何寻找其他节点， 如配置了consul则跟微服务注册一样， 注册自己到consul并通过consul做服务发现。 这里配置的是kubernetes, 通过查找当前命名空间内包含label: vault-interna=true 的 service 去发现其他的pod, 并通过label获取pod的一些状态
2. 为社么不能在启动时初始化(auto-unseal)，因为所有数据都是加密的，加密数据的密钥需要初始化时生成，并且不能保存到本地硬盘(不安全),需要人工记录, 这些密钥需要在服务启动是提供（重启），否则无法读取磁盘上数据. 官方提供了使用 k8s 的KMS服务保存这密钥从而可以自动初始化(auto-unseal), 但是KMS不是标准k8s的功能，而vault 本身主要工作就是KMS解决方案之一。 