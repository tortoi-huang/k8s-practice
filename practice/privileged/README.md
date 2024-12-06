# kubernetes 权限演示
探究各种权限的使用
## root
使用 root 用户在 pod 内部运行特权命令
```bash
# 创建并进入 busybox 容器
kubectl run -it busybox --image=busybox --restart=Never --rm -- sh
# 当前用户, 应该显示为: root
whoami
# 当前用户权限信息, 应该显示为: uid=0(root) gid=0(root) groups=0(root),10(wheel)
id
# 查看用户目录, 显示为 /root
cd ~
pwd
# 查看用户目录, 显示为 /root 下没有文件
ls ~
# 修改 root 权限文件
echo hello >> /etc/resolv.conf
# 检查修改成功
cat /etc/resolv.conf
# 修改内核信息, 这里应该提示出错, 只读文件
sysctl -w vm.max_map_count=262144
# 退出容器回到宿主机
exit

# 确认 busybox 的默认用户是 root
# kubectl run -i busybox --image=busybox --restart=Never --rm -- whoami
# kubectl run -i busybox --image=busybox --restart=Never --rm -- 
```

## runAsUser
使用 runAsUser 指向一个非 0 id用户
```bash
# 创建容器
kubectl apply -f runAsUser.yaml
kubectl exec -it pod/runasuser-pod -- sh

# 当前用户, 应该显示为: 提示出错: unknown uid 1000
whoami
# 当前用户权限信息, 应该显示为: uid=1000 gid=3000 groups=3000
id
# 查看用户目录, 显示为 /
cd ~
pwd
# 查看用户目录, 显示为 / 下的文件
ls ~
# 修改 root 权限文件, 提示没权限
echo hello >> /etc/resolv.conf
# 修改内核信息, 这里应该提示出错, 只读文件
sysctl -w vm.max_map_count=262144
# 退出容器回到宿主机
exit
kubectl delete -f runAsUser.yaml

```

## privileged
```bash
# 先在node 宿主机确认参数
grep vm.max_map_count /etc/sysctl.conf

# 创建容器
kubectl apply -f privileged.yaml
kubectl exec -it pod/privileged-pod -- sh
# 当前用户, 应该显示为: root
whoami
# 当前用户权限信息, 应该显示为: uid=0(root) gid=0(root) groups=0(root),10(wheel)
id
# 查看用户目录, 显示为 /root
cd ~
pwd
# 查看用户目录, 显示为 /root 下没有文件
ls ~
# 查看宿主机的所有进程
ps -ef
# 检查dns配置跟宿主机一样
cat /etc/resolv.conf
# 查看 ip 与宿主机一样
ip addr
# 宿主机启动监听 nc -l 9000 ,下面命令访问成功, TODO 实验时返过来在容器监听网络, 宿主机访问失败, 原因未明
wget 127.0.0.1:9000
# 修改内核信息, 成功
sysctl -w vm.max_map_count=262144
# 退出容器回到宿主机
exit

# 宿主机检查 vm.max_map_count 修改成功
sysctl vm.max_map_count

kubectl delete -f privileged.yaml
```