#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

if [ ! -n "$NODE_IP" ]; then 
    echo "variable: NODE_IP not load"
    exit 1
fi

mkdir ~/etcd
cat << EOF > ~/etcd/kubeadmcfg.yaml
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: InitConfiguration
nodeRegistration:
    name: ${NODE_NAME}
localAPIEndpoint:
    advertiseAddress: ${NODE_IP}
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${NODE_IP}"
        peerCertSANs:
        - "${NODE_IP}"
        extraArgs:
            initial-cluster: k8s1=https://${CONTROL_NODE1}:2380,k8s2=https://${CONTROL_NODE2}:2380,k8s3=https://${CONTROL_NODE3}:2380
            initial-cluster-state: new
            name: ${NODE_NAME}
            listen-peer-urls: https://${NODE_IP}:2380
            listen-client-urls: https://${NODE_IP}:2379
            advertise-client-urls: https://${NODE_IP}:2379
            initial-advertise-peer-urls: https://${NODE_IP}:2380
EOF