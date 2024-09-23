#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

if [ -n "$NODE_IP" ]; then 
    echo "'NODE_IP' not set"
    exit 0
fi

script_dir="$(dirname "$0")"
source $script_dir/env.profile

sudo tee -a /etc/profile <<-EOF
export NODE_IP=${CONTROL_NODE4}
export NODE_NAME=k8s4
EOF
source /etc/profile

if [ ! -n "$NODE_IP" ]; then 
    echo "'NODE_IP' not set"
    exit 1
fi

echo ${NODE_NAME} | sudo tee /etc/hostname
sudo hostname -F /etc/hostname

sudo sed "s/192.168.98.200\/24/${NODE_IP}\/24/g" /etc/netplan/50-cloud-init.yaml -i
sudo netplan apply 