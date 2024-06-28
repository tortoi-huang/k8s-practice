#!ps

# 删除集群
Remove-VM k8s* -Force
Remove-Item -Path $cluster_path -Recurse -Force