#!/bin/bash

# 遇到错误时停止执行后续语句
set -e
# set -x

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

# 配置 containerd cni插件
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
#           [{
#             "subnet": "10.88.0.0/16"
#           }],
#           [{
#             "subnet": "2001:4860:4860::/64"
#           }]
#         ],
#         "routes": [
#           { "dst": "0.0.0.0/0" },
#           { "dst": "::/0" }
#         ]
#       }
#     },
#     {
#       "type": "portmap",
#       "capabilities": {"portMappings": true}
#     }
#   ]
# }
# EOF