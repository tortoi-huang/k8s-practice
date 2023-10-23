# 测试一个pod多个容器的相互影响
kubernetes一个pod创建一个容器有两个nginx容器，其中一个端口8080，另外一个端口为8090，已知两个容器共享网络栈，相同端口会导致无法启动,
## 测试验证
执行部署文件

```shell
kubectl apply -f k8s.yaml
```
查看部署完成pod
```shell
kubectl get po
```
假设部署的pod名字为 muti-container-85f5c8bcc5-n92ln
进入pod的contianer查看文件,确认挂载文件不冲突，
```shell
kubectl extc -it muti-container-85f5c8bcc5-n92ln -c muti-container-nginx-c1
# 查看容器1 的配置文件正确为 8080 端口
cat /etc/nginx/conf.d/default.conf
# 查看环境变量，正确为8080
env|grep NGINX_PORT

kubectl extc -it muti-container-85f5c8bcc5-n92ln -c muti-container-nginx-c2
# 查看容器1 的配置文件正确为 8090端口
cat /etc/nginx/conf.d/default.conf
# 查看环境变量，正确为8090
env|grep NGINX_PORT
```

附加调制容器查看
```shell
# --target 表示要加入哪个容器的进程空间，没有这个参数会作为独立的进程空间运行，无法查看目标容器的进程信息
kubectl debug -it muti-container-85f5c8bcc5-n92ln --image=busybox --target muti-container-nginx-c1
# debug 容器添加后无法删除，只能删除pod， deployment会重新部署新的pod

# 使用top查看目标容器的进程信息
top
```
在docker宿主机查看dubug容器的运行，发现docker启动容器命令如下：
```shell
docker run --hostname=muti-container-85f5c8bcc5-n92ln \
  --user=0 --pid container:c624aee5f906bfe538d28cee7a05d7f2c806398e01d1cb316661555803274828 \
  --env=KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443 \
  --env=KUBERNETES_PORT_443_TCP_PROTO=tcp --env=KUBERNETES_PORT_443_TCP_PORT=443 \
  --env=KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1 --env=KUBERNETES_SERVICE_HOST=10.96.0.1 \
  --env=KUBERNETES_SERVICE_PORT=443 --env=KUBERNETES_SERVICE_PORT_HTTPS=443 \
  --env=KUBERNETES_PORT=tcp://10.96.0.1:443 \
  --env=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  --volume=/var/lib/kubelet/pods/3f3b3bf0-c1b1-46cc-9ef8-679fa5c3cfef/etc-hosts:/etc/hosts \
  --volume=/var/lib/kubelet/pods/3f3b3bf0-c1b1-46cc-9ef8-679fa5c3cfef/containers/debugger-p9scq/f65e6c6b:/dev/termination-log \
  --network=container:5d6feb2559ba5ab7cfe9b13f3c672667382e1d16015cd05e18f48116c79af04b \
  --restart=no \
  --label='annotation.io.kubernetes.container.hash=c9b316e9' \
  --label='annotation.io.kubernetes.container.restartCount=0' \
  --label='annotation.io.kubernetes.container.terminationMessagePath=/dev/termination-log' \
  --label='annotation.io.kubernetes.container.terminationMessagePolicy=File' \
  --label='annotation.io.kubernetes.pod.terminationGracePeriod=30' \
  --label='io.kubernetes.container.logpath=/var/log/pods/default_muti-container-85f5c8bcc5-n92ln_3f3b3bf0-c1b1-46cc-9ef8-679fa5c3cfef/debugger-p9scq/0.log' \
  --label='io.kubernetes.container.name=debugger-p9scq' --label='io.kubernetes.docker.type=container' \
  --label='io.kubernetes.pod.name=muti-container-85f5c8bcc5-n92ln' \
  --label='io.kubernetes.pod.namespace=default' \
  --label='io.kubernetes.pod.uid=3f3b3bf0-c1b1-46cc-9ef8-679fa5c3cfef' \
  --label='io.kubernetes.sandbox.id=5d6feb2559ba5ab7cfe9b13f3c672667382e1d16015cd05e18f48116c79af04b' \
  --runtime=runc -t -d busybox@sha256:5acba83a746c7608ed544dc1533b87c737a0b0fb730301639a0179f9344b1678
```
其中--pid指定了容器的进程空间