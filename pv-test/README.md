# 这里测试pv、pvc、storage class的创建，并测试他们之间的关系

1. 预备知识: 
    1.1. pod.volumes 可以挂载本地路径、临时卷、emptyDir、pv、csi（容器存储接口）卷、第三方存储（如nfs，云存储提供的块存储），由PersistentVolumeController负责管理生命周期
    1.2. pv(Persistent Volume) 持久制卷，管理员预先制备的存储卷，方便pod挂载，将存储过管理从pod部署中分离出来（解耦），不会因为pod的删除而被删除。
    1.3. pvc(Persistent Volume Claim), 可以理解为一个虚拟的pv，一个pv代理，或者一个pv的桥接对象，pvc会执行以下动作之一:
        1.3.1. storage class为空，创建pvc时根据volumeName属性直接绑定到一个pv上， pvc仅作为pv的代理。
        1.3.2. storage class不为，在storage class指定的挂载点(volumeBindingMode)，根据storage class查找一个pv并绑定pv和pvc，如果没有找到则根据storage class的配置动态创建一个pv并且绑定，一旦绑定后pod的删除、重启都不会再出发绑定和动态创建操作。
        pvc如果绑定了pv则删除pvc会使pv失效无法使用。
    1.4. sc(storage class), 存储类，提供一组配置，指示一个pvc是应该绑定到已有的pv还是动态创建pv，如果是动态创建怎还需要提供创建的参数。其中provisioner属性指定存储管理的实际应用程序，如果不是内置的provisioner通常运行在一个pod上，PersistentVolumeController会调用provisioner来创建和销毁pv。
2. 实验:
    2.1. 执行pod-pv.yaml创建 pv、pvc、sc， 其中:
    pvc2-without-class(pvc)手工绑定了pv，创建后状态为Bound状态，
    pvc3-with-class(pvc)动态绑定了预先制备的pv，创建后状态为Pending状态，直到第一个被pod请求该pvc，pod被删除状态不会变化, 删除pvc或导致已绑定的pv状态变为fail，无法再使用，如果pvc尚未绑定到pv则不受影响。
    name-of-storage-class3指示pvc3-with-class(pvc)等到pod消费时才会绑定到pv上。provisioner指示不会动态创建pv
    local类型pv不支持自动制备pv，暂时无法测试.
    2.2. 执行执行pod-pvc-consumer.yaml 创建po消费pvc， 检查pvc和pc的状态，原来pending的pvc会绑定到pv上，删除pod，pv、pvc状态不变
3. 其他： kubernetes有两种node,其中一种是传统的提供cpu和内存的node，另外一种是提供存储的CSINode, 这类node提供存储用来部署pv,可以通过 kubectl get CSINode 来查看