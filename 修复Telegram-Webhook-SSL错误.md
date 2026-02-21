# 修复 Telegram Bot Webhook SSL 错误

## 当前问题

Telegram Bot webhook 仍然显示 SSL 错误：
```
"last_error_message":"SSL error {error:0A000086:SSL routines::certificate verify failed}"
"pending_update_count":322
```

这说明：
- ❌ HTTPS 访问仍然失败
- ❌ 证书可能还没有正确安装到 nginx
- ❌ nginx 可能还在使用过期的证书

## 完整解决步骤

### 步骤 1: 确认证书已安装

```bash
# 检查新证书是否已安装到 nginx 配置路径
ls -la /www/server/panel/vhost/cert/telegram8.org/

# 查看证书有效期（应该是新证书，有效期到 2026-03-19）
openssl x509 -in /www/server/panel/vhost/cert/telegram8.org/fullchain.pem -noout -dates
```

**如果证书文件不存在或还是旧证书，执行：**

```bash
# 安装 ECC 证书到 nginx 配置路径
acme.sh --install-cert -d telegram8.org --ecc \
  --key-file /www/server/panel/vhost/cert/telegram8.org/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/telegram8.org/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

### 步骤 2: 检查证书文件权限

```bash
# 确保证书文件权限正确
chmod 644 /www/server/panel/vhost/cert/telegram8.org/fullchain.pem
chmod 600 /www/server/panel/vhost/cert/telegram8.org/privkey.pem
chown root:root /www/server/panel/vhost/cert/telegram8.org/*.pem
```

### 步骤 3: 检查 nginx 配置

```bash
# 查看 nginx 配置文件
cat /www/server/panel/vhost/nginx/telegram8.org.conf

# 确认 SSL 证书路径正确指向：
# ssl_certificate /www/server/panel/vhost/cert/telegram8.org/fullchain.pem;
# ssl_certificate_key /www/server/panel/vhost/cert/telegram8.org/privkey.pem;
```

### 步骤 4: 测试 nginx 配置

```bash
# 测试 nginx 配置语法
nginx -t

# 如果配置有错误，查看详细错误
nginx -t 2>&1
```

### 步骤 5: 重启 nginx

```bash
# 重启 nginx（确保使用新证书）
systemctl restart nginx

# 检查 nginx 状态
systemctl status nginx

# 如果启动失败，查看错误日志
journalctl -xe | grep nginx
tail -50 /var/log/nginx/error.log
```

### 步骤 6: 验证 HTTPS 访问

```bash
# 测试 HTTPS 访问
curl -I https://telegram8.org

# 查看在线证书有效期（应该显示新证书）
echo | openssl s_client -connect telegram8.org:443 -servername telegram8.org 2>/dev/null | openssl x509 -noout -dates

# 查看证书详细信息
echo | openssl s_client -connect telegram8.org:443 -servername telegram8.org 2>/dev/null | openssl x509 -noout -text | grep -A 2 "Validity"
```

### 步骤 7: 验证 webhook 端点可访问

```bash
# 测试 webhook 端点
curl -I https://telegram8.org/telegram/notes/JizhangARLBot

# 如果返回 200 或 404 都算正常（说明 HTTPS 工作正常）
# 如果返回 SSL 错误，说明证书还有问题
```

### 步骤 8: 重新设置 Telegram Webhook

```bash
# 删除旧的 webhook
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/deleteWebhook"

# 等待几秒后重新设置 webhook
sleep 3

# 设置新的 webhook
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://telegram8.org/telegram/notes/JizhangARLBot"}'

# 检查 webhook 状态
curl "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo"
```

## 故障排除

### 问题 1: nginx 启动失败

**检查方法：**
```bash
# 查看详细错误
nginx -t
journalctl -xe | grep nginx
tail -50 /var/log/nginx/error.log
```

**常见原因和解决方法：**

1. **证书文件路径错误**
   ```bash
   # 检查证书文件是否存在
   ls -la /www/server/panel/vhost/cert/telegram8.org/
   
   # 如果不存在，重新安装证书
   acme.sh --install-cert -d telegram8.org --ecc \
     --key-file /www/server/panel/vhost/cert/telegram8.org/privkey.pem \
     --fullchain-file /www/server/panel/vhost/cert/telegram8.org/fullchain.pem \
     --reloadcmd "systemctl reload nginx"
   ```

2. **证书文件权限问题**
   ```bash
   chmod 644 /www/server/panel/vhost/cert/telegram8.org/fullchain.pem
   chmod 600 /www/server/panel/vhost/cert/telegram8.org/privkey.pem
   ```

3. **nginx 配置语法错误**
   ```bash
   # 检查配置文件
   nginx -t
   # 根据错误信息修复配置
   ```

### 问题 2: HTTPS 访问仍然失败

**检查方法：**
```bash
# 测试 HTTPS 连接
curl -vI https://telegram8.org 2>&1 | head -30

# 查看 SSL 握手详情
openssl s_client -connect telegram8.org:443 -servername telegram8.org
```

**可能原因：**
- 证书文件损坏
- nginx 配置中证书路径错误
- 防火墙阻止 443 端口

**解决方法：**
```bash
# 重新申请并安装证书
systemctl stop nginx
acme.sh --renew -d telegram8.org --ecc --force
acme.sh --install-cert -d telegram8.org --ecc \
  --key-file /www/server/panel/vhost/cert/telegram8.org/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/telegram8.org/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
systemctl start nginx
```

### 问题 3: 证书已安装但 nginx 仍使用旧证书

**解决方法：**
```bash
# 强制重新安装证书
acme.sh --install-cert -d telegram8.org --ecc --force \
  --key-file /www/server/panel/vhost/cert/telegram8.org/privkey.pem \
  --fullchain-file /www/server/panel/vhost/cert/telegram8.org/fullchain.pem \
  --reloadcmd "systemctl reload nginx"

# 完全重启 nginx（不是 reload）
systemctl restart nginx

# 清除 nginx 缓存（如果有）
# 某些情况下需要清除浏览器或 CDN 缓存
```

### 问题 4: Telegram 仍然报告 SSL 错误

**可能原因：**
- Telegram 服务器缓存了旧的证书信息
- 证书链不完整

**解决方法：**
```bash
# 1. 确认证书链完整
openssl s_client -connect telegram8.org:443 -servername telegram8.org < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -A 5 "Issuer"

# 2. 等待几分钟让 Telegram 重新验证（Telegram 会定期重试）

# 3. 删除并重新设置 webhook
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/deleteWebhook"
sleep 5
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://telegram8.org/telegram/notes/JizhangARLBot"}'
```

## 验证清单

完成所有步骤后，运行以下命令验证：

```bash
echo "=== 1. 检查证书文件 ==="
ls -la /www/server/panel/vhost/cert/telegram8.org/

echo ""
echo "=== 2. 检查证书有效期 ==="
openssl x509 -in /www/server/panel/vhost/cert/telegram8.org/fullchain.pem -noout -dates

echo ""
echo "=== 3. 检查 nginx 状态 ==="
systemctl status nginx | head -10

echo ""
echo "=== 4. 测试 HTTPS 访问 ==="
curl -I https://telegram8.org 2>&1 | head -5

echo ""
echo "=== 5. 检查在线证书 ==="
echo | openssl s_client -connect telegram8.org:443 -servername telegram8.org 2>/dev/null | openssl x509 -noout -dates

echo ""
echo "=== 6. 检查 webhook 状态 ==="
curl -s "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo" | python -m json.tool
```

## 预期结果

修复成功后：
- ✅ nginx 正常运行
- ✅ HTTPS 访问正常（返回 200 或正确的状态码）
- ✅ 在线证书显示新证书（有效期到 2026-03-19）
- ✅ webhook 状态中 `last_error_message` 应该为空或消失
- ✅ `pending_update_count` 应该开始减少（Telegram 开始处理积压的消息）

## 注意事项

1. **等待时间**：Telegram 可能需要几分钟来重新验证证书，不要立即期望错误消失
2. **证书链**：确保使用 `fullchain.pem` 而不是单独的证书文件
3. **防火墙**：确保 443 端口已开放
4. **DNS 缓存**：如果修改了域名解析，可能需要等待 DNS 传播

## 参考链接

- [Telegram Bot API - setWebhook](https://core.telegram.org/bots/api#setwebhook)
- [Telegram Bot API - getWebhookInfo](https://core.telegram.org/bots/api#getwebhookinfo)

