#!/bin/bash

script_dir="$(dirname "$0")"
source $script_dir/env.profile
if [ ! -n "$LOADBALANCE_VIP" ]; then 
    echo "variable: LOADBALANCE_VIP not load"
    exit 1
fi
NODE_IP=$(ip addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

# 这里pod-network-cidr 需要和 cloud-vm\conf\kube-flannel.yml 匹配
# kubeadm init --control-plane-endpoint ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --apiserver-advertise-address ${NODE_IP} --upload-certs --pod-network-cidr=${POD_NETWORK_CIDR}
kubeadm init --control-plane-endpoint ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --apiserver-advertise-address ${NODE_IP} --upload-certs --pod-network-cidr=${POD_NETWORK_CIDR}
