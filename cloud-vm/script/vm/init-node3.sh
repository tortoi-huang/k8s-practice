#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

sudo tee -a /etc/profile <<-EOF
export NODE_IP=${CONTROL_NODE3}
export NODE_NAME=k8s3
EOF
source /etc/profile