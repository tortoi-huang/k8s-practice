#!/bin/bash

if [ ! -n "$APISERVER_ADVERTISE_ADDRESS" ]; then 
    echo "variable: APISERVER_ADVERTISE_ADDRESS not load"
    exit 1
fi

# 这里pod-network-cidr 需要和 cloud-vm\conf\kube-flannel.yml 匹配
# kubeadm init --control-plane-endpoint ${APISERVER_ADVERTISE_ADDRESS}:${APISERVER_DEST_PORT} --apiserver-advertise-address ${NODE_IP} --upload-certs --pod-network-cidr=10.244.0.0/16
kubeadm init --control-plane-endpoint ${LOADBALANCE_VIP}:${APISERVER_DEST_PORT} --apiserver-advertise-address ${NODE_IP} --upload-certs --pod-network-cidr=10.244.0.0/16
