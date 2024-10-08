#!/bin/bash

# 遇到错误时停止执行后续语句
set -e
# set -x

# script_dir="$(dirname "$0")"
# source $script_dir/env.profile
# if [ ! -n "$POD_NETWORK_CIDR" ]; then 
#     echo "environment variables are not set: POD_NETWORK_CIDR"
#     exit 1
# fi
# 配置 containerd cni插件
mkdir -p /etc/cni/net.d

# kubernetes 网络插件会自动生成 cni 配置, 不需要在这里独立配置, 并且这里配置会影响 kubernetes 配置, 只有在没有 kubernetes 单独使用 containerd 时才需要配置此项
# tee /etc/cni/net.d/10-containerd-net.conflist <<-EOF
# {
#   "cniVersion": "1.0.0",
#   "name": "containerd-net",
#   "plugins": [
#     {
#       "type": "bridge",
#       "bridge": "cni0",
#       "isGateway": true,
#       "ipMasq": true,
#       "promiscMode": true,
#       "ipam": {
#         "type": "host-local",
#         "ranges": [
#           [
#             {
#               "subnet": "${POD_NETWORK_CIDR}"
#             }
#           ],
#           [
#             {
#               "subnet": "${POD_NETWORK_CIDRV6}"
#             }
#           ]
#         ],
#         "routes": [
#           {
#             "dst": "0.0.0.0/0"
#           },
#           {
#             "dst": "::/0"
#           }
#         ]
#       }
#     },
#     {
#       "type": "portmap",
#       "capabilities": {
#         "portMappings": true
#       },
#       "externalSetMarkChain": "KUBE-MARK-MASQ"
#     }
#   ]
# }
# EOF
# systemctl restart containerd

sudo mkdir -p /etc/containerd

sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed "s/SystemdCgroup = false/SystemdCgroup = true/" /etc/containerd/config.toml -i

# containerd 配置文件
# sudo tee /etc/containerd/config.toml <<-"EOF"
# version = 2
# # [cgroup]
# #   driver = "systemd"
# [plugins]
#   [plugins."io.containerd.grpc.v1.cri"]
#     # systemd_cgroup = true
#     [plugins."io.containerd.grpc.v1.cri".containerd]
#       [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
#         [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#           [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#             SystemdCgroup = true

#     [plugins."io.containerd.grpc.v1.cri".registry]
#       config_path = "/etc/containerd/certs.d"
# EOF

# # 默认仓库配置
# if [ "$MIRROR_DOCKER" ]; then
# sudo tee /etc/containerd/certs.d/_default/hosts.toml <<-EOF
# [host."${MIRROR_DOCKER}"]
#   capabilities = ["pull", "resolve"]
# EOF

# # docker 仓库配置
# sudo tee /etc/containerd/certs.d/docker.io/hosts.toml <<-EOF
# server = "https://docker.io"

# [host."${MIRROR_DOCKER}"]
#   capabilities = ["pull", "resolve"]
# EOF
# fi

# # k8s 仓库配置
# if [ "$MIRROR_K8S" ]; then
# sudo tee /etc/containerd/certs.d/registry.k8s.io/hosts.toml <<-EOF
# server = "https://registry.k8s.io"

# [host."${MIRROR_K8S}"]
#   capabilities = ["pull", "resolve"]
# EOF
# fi
