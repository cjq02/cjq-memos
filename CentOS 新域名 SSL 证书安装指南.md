# CentOS 新域名 SSL 证书安装指南

## 概述

本指南介绍如何在 CentOS 服务器上为新域名安装 Let's Encrypt SSL 证书，使用 acme.sh 工具进行自动化证书管理。

## 前置条件

- CentOS 7/8 服务器
- 已安装 nginx 或其他 Web 服务器
- 域名已正确解析到服务器 IP
- 服务器已开放 80 和 443 端口
- 具有 root 或 sudo 权限

## 环境信息

- **操作系统**：CentOS 7/8
- **Web 服务器**：nginx
- **证书类型**：Let's Encrypt（支持 RSA 和 ECC）
- **证书管理工具**：acme.sh

## 安装步骤

### 1. 安装 acme.sh 证书管理工具

```bash
# 下载并安装 acme.sh
curl https://get.acme.sh | sh

# 重新加载环境变量
source ~/.bashrc

# 或者重新登录终端

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

### 3. 准备域名和目录

```bash
# 设置域名变量（替换为您的域名）
DOMAIN="example.com"
WWW_DOMAIN="www.example.com"

# 创建证书存储目录（根据您的服务器配置调整路径）
mkdir -p /www/server/panel/vhost/cert/${DOMAIN}
# 或者使用标准路径
# mkdir -p /etc/nginx/ssl/${DOMAIN}
```

### 4. 申请 SSL 证书

根据您的服务器环境，选择以下三种方式之一：

#### 方式一：Standalone 模式（推荐，最简单）

适用于：服务器上没有运行 Web 服务器，或可以临时停止 Web 服务器

```bash
# 停止 nginx（如果正在运行）
systemctl stop nginx

# 申请证书（单个域名）
acme.sh --issue -d ${DOMAIN} --standalone

# 申请证书（包含 www 子域名）
acme.sh --issue -d ${DOMAIN} -d ${WWW_DOMAIN} --standalone

# 启动 nginx
systemctl start nginx
```

#### 方式二：Webroot 模式（推荐，无需停止服务）

适用于：nginx 正在运行，且网站已配置好

```bash
# 确保网站根目录存在（根据实际情况调整）
WEBROOT="/www/wwwroot/${DOMAIN}"

# 申请证书（单个域名）
acme.sh --issue -d ${DOMAIN} --webroot ${WEBROOT}

# 申请证书（包含 www 子域名）
acme.sh --issue -d ${DOMAIN} -d ${WWW_DOMAIN} --webroot ${WEBROOT}
```

#### 方式三：Nginx 模式（自动配置）

适用于：使用 nginx，且希望 acme.sh 自动配置验证

```bash
# 申请证书（acme.sh 会自动配置 nginx）
acme.sh --issue -d ${DOMAIN} --nginx

# 申请证书（包含 www 子域名）
acme.sh --issue -d ${DOMAIN} -d ${WWW_DOMAIN} --nginx
```

### 5. 安装证书到 nginx

```bash
# 方式一：使用宝塔面板路径（如果使用宝塔面板）
acme.sh --install-cert -d ${DOMAIN} \
  --key-file /www/server/panel/vhost/cert/${DOMAIN}/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem \
  --reloadcmd "systemctl reload nginx"

# 方式二：使用标准路径
acme.sh --install-cert -d ${DOMAIN} \
  --key-file /etc/nginx/ssl/${DOMAIN}/privkey.pem \
  --fullchain-file /etc/nginx/ssl/${DOMAIN}/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

### 6. 配置 nginx SSL

创建或编辑 nginx 配置文件：

```bash
# 宝塔面板路径
vi /www/server/panel/vhost/nginx/${DOMAIN}.conf

# 或标准路径
vi /etc/nginx/conf.d/${DOMAIN}.conf
```

添加以下 SSL 配置：

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # HTTP 重定向到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL 证书配置
    ssl_certificate /www/server/panel/vhost/cert/example.com/fullchain.pem;
    ssl_certificate_key /www/server/panel/vhost/cert/example.com/privkey.pem;
    
    # SSL 优化配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 网站根目录（根据实际情况调整）
    root /www/wwwroot/example.com;
    index index.html index.htm index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # PHP 配置（如果使用 PHP）
    location ~ \.php$ {
        fastcgi_pass unix:/tmp/php-cgi.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # 错误页面
    error_page 497 https://$server_name$request_uri;
}
```

### 7. 测试并重启 nginx

```bash
# 测试 nginx 配置
nginx -t

# 如果测试通过，重启 nginx
systemctl restart nginx

# 检查 nginx 状态
systemctl status nginx
```

### 8. 验证证书安装

```bash
# 检查证书文件
ls -la /www/server/panel/vhost/cert/${DOMAIN}/

# 查看证书有效期
openssl x509 -in /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem -noout -dates

# 测试 SSL 连接
openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} 2>/dev/null | openssl x509 -noout -dates

# 测试 HTTPS 访问
curl -I https://${DOMAIN}

# 使用浏览器访问 https://${DOMAIN} 验证
```

### 9. 设置自动续期

```bash
# 启用自动续期
acme.sh --upgrade --auto-upgrade

# 查看证书列表
acme.sh --list

# 查看特定域名的证书信息
acme.sh --info -d ${DOMAIN}

# 查看证书信息（检查是否需要续期）
acme.sh --info -d ${DOMAIN}

# 注意：某些版本的 acme.sh 不支持 --dry-run 参数
# 可以使用以下命令检查证书有效期：
openssl x509 -in /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem -noout -dates
```

## 申请 ECC 证书（可选）

ECC 证书具有更好的性能和安全性：

```bash
# 申请 ECC 证书
acme.sh --issue -d ${DOMAIN} --standalone --keylength ec-256

# 安装 ECC 证书
acme.sh --install-cert -d ${DOMAIN} --ecc \
  --key-file /www/server/panel/vhost/cert/${DOMAIN}/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

## 多域名证书

如果需要为多个域名申请证书：

```bash
# 申请包含多个域名的证书
acme.sh --issue -d example.com -d www.example.com -d api.example.com --standalone

# 安装证书
acme.sh --install-cert -d example.com \
  --key-file /www/server/panel/vhost/cert/example.com/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/example.com/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

## 证书管理命令

```bash
# 查看所有证书
acme.sh --list

# 查看证书详细信息
acme.sh --info -d ${DOMAIN}

# 手动续期证书
acme.sh --renew -d ${DOMAIN}

# 强制续期证书
acme.sh --renew -d ${DOMAIN} --force

# 撤销证书
acme.sh --revoke -d ${DOMAIN}

# 删除证书
acme.sh --remove -d ${DOMAIN}
```

## 证书有效期检查

### 方法一：查看本地证书文件

```bash
# 查看证书有效期
openssl x509 -in /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem -noout -dates

# 查看证书详细信息
openssl x509 -in /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem -text -noout

# 检查证书是否在30天内过期
openssl x509 -in /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem -noout -checkend 2592000
```

### 方法二：通过 HTTPS 连接查看

```bash
# 查看在线证书有效期
echo | openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} 2>/dev/null | openssl x509 -noout -dates
```

### 方法三：创建证书监控脚本

```bash
# 创建证书检查脚本
cat > /root/check_ssl_cert.sh << 'EOF'
#!/bin/bash
DOMAIN="example.com"  # 修改为您的域名
CERT_FILE="/www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem"

echo "=== SSL证书有效期检查 ==="
echo "域名: $DOMAIN"
echo "检查时间: $(date)"
echo ""

if [ -f "$CERT_FILE" ]; then
    echo "本地证书文件有效期:"
    openssl x509 -in "$CERT_FILE" -noout -dates
    echo ""
    
    if openssl x509 -in "$CERT_FILE" -noout -checkend 2592000; then
        echo "✅ 证书有效期正常（30天内不会过期）"
    else
        echo "⚠️  警告：证书将在30天内过期！"
    fi
else
    echo "❌ 证书文件不存在: $CERT_FILE"
fi

echo ""
echo "在线证书有效期:"
if echo | openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null | openssl x509 -noout -dates; then
    echo "✅ 在线证书检查成功"
else
    echo "❌ 无法连接到 ${DOMAIN}:443"
fi
EOF

# 给脚本添加执行权限
chmod +x /root/check_ssl_cert.sh

# 运行检查脚本
/root/check_ssl_cert.sh
```

## 配置文件位置

根据您的服务器配置，证书和配置文件可能位于以下位置：

### 宝塔面板路径
- **nginx 主配置**：`/www/server/nginx/conf/nginx.conf`
- **虚拟主机配置**：`/www/server/panel/vhost/nginx/${DOMAIN}.conf`
- **SSL 证书目录**：`/www/server/panel/vhost/cert/${DOMAIN}/`
- **acme.sh 证书目录**：`/root/.acme.sh/${DOMAIN}_ecc/` 或 `/root/.acme.sh/${DOMAIN}/`

### 标准路径
- **nginx 主配置**：`/etc/nginx/nginx.conf`
- **虚拟主机配置**：`/etc/nginx/conf.d/${DOMAIN}.conf` 或 `/etc/nginx/sites-available/${DOMAIN}`
- **SSL 证书目录**：`/etc/nginx/ssl/${DOMAIN}/`
- **acme.sh 证书目录**：`/root/.acme.sh/${DOMAIN}_ecc/` 或 `/root/.acme.sh/${DOMAIN}/`

## 故障排除

### 1. nginx 启动失败

```bash
# 检查 nginx 配置语法
nginx -t

# 查看 nginx 错误日志
tail -f /var/log/nginx/error.log
# 或
journalctl -xe | grep nginx
```

### 2. 证书申请失败

```bash
# 使用调试模式查看详细错误
acme.sh --issue -d ${DOMAIN} --standalone --debug

# 检查域名解析
nslookup ${DOMAIN}
dig ${DOMAIN}

# 检查端口是否开放
netstat -tlnp | grep -E ':(80|443)'
# 或
ss -tlnp | grep -E ':(80|443)'

# 检查防火墙
firewall-cmd --list-ports
# 如果需要开放端口
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

### 3. 证书验证失败

```bash
# 检查网站是否可以访问
curl -I http://${DOMAIN}

# 检查 .well-known 目录权限（webroot 模式）
ls -la /www/wwwroot/${DOMAIN}/.well-known/acme-challenge/

# 检查 nginx 配置是否正确指向网站根目录
```

### 4. HTTPS 访问失败

```bash
# 检查 SSL 证书
openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN}

# 检查证书文件权限
ls -la /www/server/panel/vhost/cert/${DOMAIN}/

# 确保证书文件可读
chmod 644 /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem
chmod 600 /www/server/panel/vhost/cert/${DOMAIN}/privkey.pem
```

### 5. 证书续期失败

```bash
# 手动测试续期
acme.sh --renew -d ${DOMAIN} --force --debug

# 检查自动续期任务
crontab -l | grep acme

# 查看 acme.sh 日志
tail -f ~/.acme.sh/acme.sh.log
```

### 6. 证书过期问题

```bash
# 检查证书是否过期
openssl x509 -in /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem -noout -checkend 0

# 强制续期证书
acme.sh --renew -d ${DOMAIN} --force

# 重新安装证书
acme.sh --install-cert -d ${DOMAIN} \
  --key-file /www/server/panel/vhost/cert/${DOMAIN}/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/${DOMAIN}/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

## 注意事项

1. **域名解析**：确保域名已正确解析到服务器 IP，且 80 和 443 端口已开放
2. **证书有效期**：Let's Encrypt 证书有效期为 90 天，acme.sh 会自动续期
3. **证书备份**：建议定期备份证书文件
4. **监控续期**：虽然设置了自动续期，建议定期检查证书状态
5. **CentOS 7 镜像源**：CentOS 7 已停止维护，建议使用阿里云或清华镜像源
6. **防火墙配置**：确保防火墙允许 80 和 443 端口访问
7. **SELinux**：如果启用了 SELinux，可能需要配置相关策略
8. **证书类型选择**：
   - RSA 证书：兼容性更好，适用于大多数场景
   - ECC 证书：性能更好，安全性更高，但部分旧设备可能不支持

## 完成检查清单

- [ ] acme.sh 已安装并注册
- [ ] SSL 证书申请成功
- [ ] 证书已安装到指定目录
- [ ] nginx 配置已更新并测试通过
- [ ] nginx 服务正常运行
- [ ] HTTPS 访问正常
- [ ] 证书自动续期已配置
- [ ] 证书有效期检查脚本已创建（可选）

## 相关资源

- [acme.sh 官方文档](https://github.com/acmesh-official/acme.sh)
- [Let's Encrypt 官网](https://letsencrypt.org/)
- [SSL Labs SSL 测试](https://www.ssllabs.com/ssltest/) - 测试 SSL 配置

---

**最后更新**：2025-01-XX  
**适用系统**：CentOS 7/8  
**证书类型**：Let's Encrypt (RSA/ECC)

