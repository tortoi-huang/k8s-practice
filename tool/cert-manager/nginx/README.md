# cert-manager nginx demo
自定义一个CA认证机构，并使用该认证机构签名各个应用的私钥.

## 步骤
1. 定义一个自签名的 root ca 证书生成实例 ClusterIssuer: selfsigned-issuer-ca
2. 定义一个证书申请实例 Issuer: nginx-tls-demo-issuer, 
3. 生成CA 证书 Certificate: root-selfsigned-ca, 并标识为这是一个CA 证书
4. 生成服务端证书: Certificate: nginx-tls-server-cert
5. 生成客户端证书: Certificate: nginx-tls-client-cert
6. 创建nginx 服务并挂载和配置证书, 并启动客户端认证
7. 使用curl 访问nginx https地址, 只有配置了正确的ca 和客户端证书和私钥才能正确访问
## 安装 CA
```shell
# 创建根证书, 服务端证书和客户端证书
kubectl -n mw apply -f nginx-demo-cert.yaml

# 查看安装结果
kubectl get ClusterIssuer
kubectl -n mw get Issuer
kubectl -n mw get Certificate

#逐个查看内容 tls 证书内容
kubectl -n mw get secret/nginx-tls-server-cert -o yaml
kubectl -n mw get secret/nginx-tls-client-cert -o yaml
kubectl -n mw get secret/root-ca-secret -o yaml
```

## 安装nginx服务
```shell
kubectl -n mw apply -f nginx-demo-server.yaml


# 登录到 nginx pod, 或者登录到其他挂载了证书的pod
# http访问正常
curl http://nginx-tls-server

# https 忽略警告, 如果nginx配置了mtls(ssl_verify_client on)则返回失败，必须提供身份验证
curl -k https://nginx-tls-server
# https 指定ca, nginx没有启用mtls(ssl_verify_client)则没有警告, 如果nginx配置可mtls则返回失败，必须提供身份验证
curl --cacert /certs/ca.crt https://nginx-tls-server

# mtls 双向tls认证
curl --cacert /certs/ca.crt --cert /certs/tls.crt --key /certs/tls.key https://nginx-tls-server

# 访问失败，域名不匹配
curl --cacert /certs/ca.crt --cert /certs/tls.crt --key /certs/tls.key https://localhost
```