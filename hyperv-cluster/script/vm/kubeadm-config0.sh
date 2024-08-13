apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: " 1.30.0" 
# 这里填入您的负载均衡器地址
controlPlaneEndpoint: "${APISERVER_ADVERTISE_ADDRESS}:${APISERVER_SRC_PORT}" 
networking:
#   podSubnet: "192.168.0.0/16"
  serviceSubnet: "10.96.0.0/12" 
#   dnsDomain: "cluster.local"

apiServer:
  extraArgs:
    enable-admission-plugins: "NamespaceLifecycle,LimitRanger,ServiceQuota,NodeRestriction,SecurityContextDeny,ResourceQuota"

controllerManager: {}
scheduler: {}

dns: 
  type: CoreDNS
etcd:
  local:    
    dataDir: /var/lib/etcd
    
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  kubeletExtraArgs:
    NodeIP: "YOUR_NODE_IP" # 替换为节点的 IP 地址
  criSocket: "/var/run/dockershim.sock"

# 添加控制平面节点设置
controlPlane:
  local:
    extraArgs:
      advertise-address: "YOUR_NODE_IP" # 替换为节点的 IP 地址
