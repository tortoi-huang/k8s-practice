# 验证java容器支持
在没有容器支持之前， java运行在容器里会看到整个node的资源，如果没有设定-Xmx -Xms等参数，那么容器里的java会按运行在容器外的规则使用整个node的25%内存容量， 容易超出配额导致kubernates kill掉容器

java对容器的支持分为对cgroup v1支持和 cgroup v2支持两个阶段：
以下版本对对cgroup v1支持， 如果node节点只支持 cgroup v2则无法开启Java对容器的支持, 所以需要先确定node节点支持的cgroup 版本
java 从 java10 版本及之后的所有版本 -XX:-UseContainerSupport
java 8 也在 8u191 小版本开始支持 -XX:-UseContainerSupport
java 9 具体哪个小版本号开始支持没有调研

java15 以后对cgroup v1和 cgroup v2都支持

```shell

# 登录pod
kubectl exec -it pod//tc1-5b97b9bdd7-h7jsj -n mw -- sh
# pod中执行命令
# 显示 UseContainerSupport=true 默认值
java -XX:+PrintFlagsFinal -version|grep UseContainerSupport

java -XX:+PrintFlagsFinal -version|grep ActiveProcessorCount

# 使用默认值
java  -XX:+PrintFlagsFinal -version|grep Percentage
java  -XX:+PrintFlagsFinal -version|grep HeapSize

# 指定参数, 这里可以看到实际使用的 是limit 的百分比, 不是node的
java -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=75.0 -XX:MinRAMPercentage=75.0 -XX:+PrintFlagsFinal -version|grep HeapSize
```