
# CentOS 7 服务器 SSL 证书重新安装指南

## 问题背景

服务器 `telegram8.org` 的 SSL 证书已过期，导致 Telegram Bot webhook 出现 SSL 错误：
```
last_error_message: "SSL error {error:0A000086:SSL routines::certificate verify failed}"
```

证书有效期：`notAfter=Sep 18 15:11:51 2025 GMT`（已过期）

## 环境信息

- **操作系统**：CentOS 7
- **Web 服务器**：nginx 1.24.0
- **应用框架**：webman (PHP)
- **域名**：telegram8.org
- **证书类型**：Let's Encrypt ECC 证书

## 解决步骤

### 1. 安装 acme.sh 证书管理工具

```bash
# 下载并安装 acme.sh
curl https://get.acme.sh | sh

# 重新加载环境变量
source ~/.bashrc

# 测试安装
acme.sh --version
```

### 2. 注册 acme.sh 账户

```bash
# 注册账户（替换为您的邮箱）
acme.sh --register-account -m your-email@example.com

# 设置默认 CA 为 Let's Encrypt
acme.sh --set-default-ca --server letsencrypt
```

### 3. 临时禁用 SSL 配置

由于证书文件损坏导致 nginx 无法启动，需要先注释掉 SSL 相关配置：

```bash
# 备份原始配置
cp /www/server/panel/vhost/nginx/telegram8.org.conf /www/server/panel/vhost/nginx/telegram8.org.conf.bak

# 注释掉 SSL 相关配置
sed -i 's/^    listen 443 ssl http2;/#    listen 443 ssl http2;/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    listen \[::\]:443 ssl http2;/#    listen \[::\]:443 ssl http2;/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_certificate/#    ssl_certificate/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_certificate_key/#    ssl_certificate_key/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_protocols/#    ssl_protocols/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_ciphers/#    ssl_ciphers/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_prefer_server_ciphers/#    ssl_prefer_server_ciphers/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_session_cache/#    ssl_session_cache/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    ssl_session_timeout/#    ssl_session_timeout/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    add_header Strict-Transport-Security/#    add_header Strict-Transport-Security/' /www/server/panel/vhost/nginx/telegram8.org.conf
sed -i 's/^    error_page 497/#    error_page 497/' /www/server/panel/vhost/nginx/telegram8.org.conf
```

### 4. 启动 nginx 服务

```bash
# 测试 nginx 配置
nginx -t

# 启动 nginx
systemctl start nginx

# 检查 nginx 状态
systemctl status nginx
```

### 5. 申请新的 SSL 证书

使用 standalone 模式申请证书（需要停止 nginx）：

```bash
# 停止 nginx
systemctl stop nginx

# 申请证书
acme.sh --issue -d telegram8.org --standalone

# 启动 nginx
systemctl start nginx
```

### 6. 安装证书到 nginx

```bash
# 安装证书
acme.sh --install-cert -d telegram8.org \
  --key-file /www/server/panel/vhost/cert/telegram8.org/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/telegram8.org/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

### 7. 恢复 SSL 配置

```bash
# 恢复原始配置
cp /www/server/panel/vhost/nginx/telegram8.org.conf.bak /www/server/panel/vhost/nginx/telegram8.org.conf

# 重启 nginx
systemctl restart nginx

# 检查 nginx 状态
systemctl status nginx
```

### 8. 验证证书安装

```bash
# 检查证书文件
ls -la /www/server/panel/vhost/cert/telegram8.org/

# 检查证书有效期
openssl x509 -in /www/server/panel/vhost/cert/telegram8.org/fullchain.pem -noout -dates

# 测试 SSL 连接
openssl s_client -connect telegram8.org:443 -servername telegram8.org 2>/dev/null | openssl x509 -noout -dates

# 测试 HTTPS 访问
curl -I https://telegram8.org
```

### 9. 设置 Telegram Bot Webhook

```bash
# 设置 HTTPS webhook
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://telegram8.org/telegram/notes/JizhangARLBot"}'

# 检查 webhook 状态
curl "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo"
```

### 10. 设置自动续期

```bash
# 设置自动续期
acme.sh --upgrade --auto-upgrade

# 查看证书列表
acme.sh --list
```

## 配置文件位置

- **nginx 主配置**：`/www/server/nginx/conf/nginx.conf`
- **虚拟主机配置**：`/www/server/panel/vhost/nginx/telegram8.org.conf`
- **SSL 证书目录**：`/www/server/panel/vhost/cert/telegram8.org/`
- **acme.sh 证书目录**：`/root/.acme.sh/telegram8.org_ecc/`

## 证书信息

- **证书类型**：ECC (Elliptic Curve Cryptography)
- **密钥长度**：ec-256
- **颁发机构**：Let's Encrypt
- **有效期**：90 天（自动续期）

## 注意事项

1. **CentOS 7 镜像源问题**：由于 CentOS 7 已停止维护，部分镜像源不可用，建议使用阿里云或清华镜像源
2. **socat 依赖**：standalone 模式需要 socat 工具，如果安装失败可使用 webroot 模式
3. **证书备份**：建议定期备份证书文件
4. **监控续期**：虽然设置了自动续期，建议定期检查证书状态

## 故障排除

### nginx 启动失败
```bash
# 检查 nginx 配置语法
nginx -t

# 查看 nginx 错误日志
journalctl -xe | grep nginx
```

### 证书申请失败
```bash
# 使用调试模式
acme.sh --issue -d telegram8.org --standalone --debug

# 检查域名解析
nslookup telegram8.org
```

### webhook 设置失败
```bash
# 检查 HTTPS 访问
curl -I https://telegram8.org

# 检查 SSL 证书
openssl s_client -connect telegram8.org:443 -servername telegram8.org
```

## 完成状态

✅ SSL 证书申请成功  
✅ 证书安装到 nginx  
✅ nginx 服务正常运行  
✅ HTTPS 访问正常  
✅ Telegram Bot webhook 设置成功  

---

**生成时间**：2025-09-20  
**操作人员**：系统管理员  
**服务器**：telegram8.org (97.74.90.229)