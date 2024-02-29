
# 安装
使用helm生成yaml文件使用 kubectl安装。
```shell
# helm pull hashicorp/vault --version 0.27.0
# tar -xzf vault-0.27.0.tgz
# cp vault/values.yaml values.yaml
helm template vault hashicorp/vault -n mw --version 0.27.0 --include-crds --values helm-vault-raft-values.yaml > helm-vault-raft-values-0.27.0.yaml

kubectl apply -f helm-vault-raft-values-0.27.0.yaml
# helm install vault hashicorp/vault -n mw --version 0.27.0 --values helm-vault-raft-values.yaml
```

# 初始化
vault刚安装好是不能使用的，pod 状态不为 ready， 需要初始化。
原因是vaul需要生成加密暑假的密钥, 称为share key, 另外这些密钥和数据存储在一起，通过一个 root key(root token) 加密， root key也是存储在磁盘上的，但是不会和share key一起存放， root key是使用 share key加密存储的(Shamir's secret sharing)。
服务初始化会生成几个 share key 和一个 root key, 并加密保存起来。

服务启动(重启)时需要提供一定数量(Threshold)的 share key 来解密 root key 才能完成启动。 这个动作称为unseal. 
对于google, aws 等大型云厂商集群提供了可靠的密钥存储服务(KMS)，可以用来保存这些share key, 可以使用 Auto unseal功能， 自建的 kubernetes集群还不支持(vault的作用本来就是kms, 有kms还要部署vault干啥?)。

以下通过shell 命令生成 实际也可以通过 首次访问ui时通过ui界面操作: http://localhost:8200/ui
```shell
# 初始化生成节点的 share key 和 root key, 集群的每个节点都要单独初始化
kubectl exec -it pod/vault-0 -n mw -- vault operator init
# Unseal Key 1: pWFgnxUtv9ZSLoepf/a7bNjw788sXn7sWobbj5pEwLVv
# Unseal Key 2: PQqNtn5ylucNMeP9N3jao80SIcfXx9hVASeHzUS3xzDQ
# Unseal Key 3: WvUGEeDBg997YMa3fuNVzscmPb5MDgByY6fC2I/L742A
# Unseal Key 4: u7hWob63Ykt7wAASyRRBwwYhwOiuF5RMWAtjXkZGoKGD
# Unseal Key 5: BVZYYazLYYrmCi9mYrTWEBDA+HOTEBTNoZsXK/KEkFsX

# Initial Root Token: hvs.iHCXzUSlUVbrHaNEdnAGLsWl

# 每次启动需要提供至少3个share key 来解封节点，其实时解密 root key
kubectl exec -it pod/vault-0 -n mw -- vault operator unseal pWFgnxUtv9ZSLoepf/a7bNjw788sXn7sWobbj5pEwLVv
kubectl exec -it pod/vault-0 -n mw -- vault operator unseal PQqNtn5ylucNMeP9N3jao80SIcfXx9hVASeHzUS3xzDQ
kubectl exec -it pod/vault-0 -n mw -- vault operator unseal WvUGEeDBg997YMa3fuNVzscmPb5MDgByY6fC2I/L742A
# kubectl exec -it pod/vault-0 -n mw -- vault operator unseal u7hWob63Ykt7wAASyRRBwwYhwOiuF5RMWAtjXkZGoKGD
# kubectl exec -it pod/vault-0 -n mw -- vault operator unseal BVZYYazLYYrmCi9mYrTWEBDA+HOTEBTNoZsXK/KEkFsX


kubectl exec -it pod/vault-1 -n mw -- vault operator init
Unseal Key 1: IHhTQOi+P66r5tBg9BwOiPqZJ2XuxIZ8CRwSa362vfDz
Unseal Key 2: bPRqf1kjNyTL30kM4Bl70WjWjnRO3pnGP7qKkA60/KKt
Unseal Key 3: pMUOuz8XpkB0JGjVVm+I7ki2OMzv657oV0er+fCl0dJY
Unseal Key 4: Asi2MjOkYj2aag8SUvf3runsGSomhixNQRXc/ffSx2KO
Unseal Key 5: IDalhQcFOZhs1LCqxnu9V4nG9wWWNbKiz0EcuIDPP9z+

Initial Root Token: hvs.DIqFtjivXha2d24DXaynIi8Q
kubectl exec -it pod/vault-1 -n mw -- vault operator unseal IHhTQOi+P66r5tBg9BwOiPqZJ2XuxIZ8CRwSa362vfDz
kubectl exec -it pod/vault-1 -n mw -- vault operator unseal bPRqf1kjNyTL30kM4Bl70WjWjnRO3pnGP7qKkA60/KKt
kubectl exec -it pod/vault-1 -n mw -- vault operator unseal pMUOuz8XpkB0JGjVVm+I7ki2OMzv657oV0er+fCl0dJY
# kubectl exec -it pod/vault-1 -n mw -- vault operator unseal Asi2MjOkYj2aag8SUvf3runsGSomhixNQRXc/ffSx2KO
# kubectl exec -it pod/vault-1 -n mw -- vault operator unseal IDalhQcFOZhs1LCqxnu9V4nG9wWWNbKiz0EcuIDPP9z+

kubectl exec -it pod/vault-2 -n mw -- vault operator init
# Unseal Key 1: uyfCBhC7+cLMNfEJViFuqimOaU2Y7hatG23V9g94PNLB
# Unseal Key 2: ss4MKXugcyVTxqYYoKDiHBMG8gQGLW1uZNs3HVsC3syi
# Unseal Key 3: oS9FfxIPu9NCWS061J6u6tYKVO47wt9DhnFn0M7riEbx
# Unseal Key 4: EwFhbZLo8zsI07Dn5v+IAMCrAy///IY7h4Yio3kECczr
# Unseal Key 5: vYfekMom/RkdvW+fjrglTXeJfZ3DsQGULGCYXdEh6lTM

# Initial Root Token: hvs.6OxRW3TaTGySvrQ2qunx0zXr
kubectl exec -it pod/vault-2 -n mw -- vault operator unseal uyfCBhC7+cLMNfEJViFuqimOaU2Y7hatG23V9g94PNLB
kubectl exec -it pod/vault-2 -n mw -- vault operator unseal ss4MKXugcyVTxqYYoKDiHBMG8gQGLW1uZNs3HVsC3syi
kubectl exec -it pod/vault-2 -n mw -- vault operator unseal oS9FfxIPu9NCWS061J6u6tYKVO47wt9DhnFn0M7riEbx
# kubectl exec -it pod/vault-2 -n mw -- vault operator unseal EwFhbZLo8zsI07Dn5v+IAMCrAy///IY7h4Yio3kECczr
# kubectl exec -it pod/vault-2 -n mw -- vault operator unseal vYfekMom/RkdvW+fjrglTXeJfZ3DsQGULGCYXdEh6lTM
```

# 访问web UI
```shell
# 代理服务地址，随机路由到后端pod
kubectl port-forward service/vault 8200:http -n mw

# 代理pod地址
kubectl port-forward pod/vault-0 8200:http -n mw
```
## 首次登录
首次登录需要用 root key(root token) 登录, 因为每个pod的root key不同, 需要登录到指定的pod 创建用户后可以使用用户登录任意pod
访问地址(假如pod地址代理到 localhost): http://localhost:8200/ui/vault/auth?with=token
### 创建用户
使用pod的root token登录，进入 dashboard界面， 进入 access/Authentication Methods: 点击"Enable new Method"功能添加认证方式，这里选择 username & password模式新建名为为userpass，保存后回到 access/Authentication Methods 界面，点击新的userpass 行，添加用户

### 登录集群
使用用户和用户名可用登录到任意一个pod，并且共享session. 使用vault集群的 service 地址登录，选择用户名和密码模式，输入上一步创建的用户名和密码登录

# 问题
1. pod启动后是如何知道vault集群的其他节点的？ 通过配置文件中的 service_registration配置决定如何寻找其他节点， 如配置了consul则跟微服务注册一样， 注册自己到consul并通过consul做服务发现。 这里配置的是kubernetes, 通过查找当前命名空间内包含label: vault-interna=true 的 service 去发现其他的pod, 并通过label获取pod的一些状态
2. 为社么不能在启动时初始化(auto-unseal)，因为所有数据都是加密的，加密数据的密钥需要初始化时生成，并且不能保存到本地硬盘(不安全),需要人工记录, 这些密钥需要在服务启动是提供（重启），否则无法读取磁盘上数据. 官方提供了使用 k8s 的KMS服务保存这密钥从而可以自动初始化(auto-unseal), 但是KMS不是标准k8s的功能，而vault 本身主要工作就是KMS解决方案之一。 