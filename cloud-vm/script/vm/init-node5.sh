#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

sudo tee -a /etc/profile <<-EOF
export NODE_IP=${CONTROL_NODE5}
export NODE_NAME=k8s5
EOF
source /etc/profile