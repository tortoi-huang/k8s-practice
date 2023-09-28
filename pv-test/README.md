# 这里测试pv、pvc、storage class的创建，并测试他们之间的关系
1. 执行pod-pv.yaml创建 pv、pvc、storage class， 其中 
pvc2-without-class手工绑定了pv，创建后状态为Bound状态，
pvc3-with-class动态绑定了预先制备的pv，创建后状态为Pending状态，知道第一个被pod请求该pvc，pod被删除状态不会变化
删除pvc或导致已绑定的pv状态变为fail，无法再使用，如果pvc尚未绑定到pv则不受影响。
local类型pv不支持自动制备pv，暂时无法测试.
2. 执行执行pod-pvc-consumer.yaml 创建po消费pvc， 检查pvc和pc的状态，原来pending的pvc会绑定到pv上，删除pod，pv、pvc状态不变