#!/bin/bash

# 遇到错误时停止执行后续语句
set -e

sudo tee -a /etc/profile <<-EOF
export NODE_IP=192.168.98.204
export NODE_NAME=k8s4
EOF
source /etc/profile