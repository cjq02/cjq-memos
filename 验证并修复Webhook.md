# 验证并修复 Telegram Webhook

## ✅ 当前状态

- ✅ 证书已正确安装（有效期到 2026-03-19）
- ✅ nginx 正常运行
- ✅ HTTPS 访问正常（返回 200 OK）
- ⏳ 需要重新设置 Telegram webhook

## 立即执行的步骤

### 1. 验证在线证书

```bash
# 确认在线证书是新证书（应该显示有效期到 2026-03-19）
echo | openssl s_client -connect telegram8.org:443 -servername telegram8.org 2>/dev/null | openssl x509 -noout -dates
```

### 2. 测试 webhook 端点

```bash
# 测试 webhook 端点是否可访问
curl -I https://telegram8.org/telegram/notes/JizhangARLBot
```

### 3. 重新设置 Telegram Webhook

```bash
# 步骤 1: 删除旧的 webhook（清除错误状态）
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/deleteWebhook"

# 步骤 2: 等待几秒
sleep 3

# 步骤 3: 重新设置 webhook
curl -X POST "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://telegram8.org/telegram/notes/JizhangARLBot"}'

# 步骤 4: 检查 webhook 状态
curl -s "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo" | python -m json.tool
```

如果没有 `python`，可以使用：

```bash
# 使用 jq（如果已安装）
curl -s "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo" | jq .

# 或者直接查看原始 JSON
curl -s "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo"
```

## 完整验证脚本

运行以下命令进行完整验证：

```bash
echo "=== 1. 检查本地证书有效期 ==="
openssl x509 -in /www/server/panel/vhost/cert/telegram8.org/fullchain.pem -noout -dates

echo ""
echo "=== 2. 检查在线证书有效期 ==="
echo | openssl s_client -connect telegram8.org:443 -servername telegram8.org 2>/dev/null | openssl x509 -noout -dates

echo ""
echo "=== 3. 测试 HTTPS 访问 ==="
curl -I https://telegram8.org 2>&1 | head -3

echo ""
echo "=== 4. 测试 webhook 端点 ==="
curl -I https://telegram8.org/telegram/notes/JizhangARLBot 2>&1 | head -3

echo ""
echo "=== 5. 检查 webhook 状态 ==="
curl -s "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo"
```

## 预期结果

### 成功后的 webhook 状态应该显示：

```json
{
  "ok": true,
  "result": {
    "url": "https://telegram8.org/telegram/notes/JizhangARLBot",
    "has_custom_certificate": false,
    "pending_update_count": 322,  // 这个数字会逐渐减少
    "last_error_date": 0,  // 应该为 0 或不存在
    "last_error_message": "",  // 应该为空或不存在
    "max_connections": 40,
    "ip_address": "97.74.90.229"
  }
}
```

### 关键指标：

- ✅ `last_error_message`: 应该为空或不存在
- ✅ `last_error_date`: 应该为 0 或不存在
- ✅ `pending_update_count`: 会逐渐减少（Telegram 开始处理积压的消息）
- ✅ `url`: 正确指向 webhook 地址

## 注意事项

1. **等待时间**：Telegram 可能需要几分钟来重新验证证书和处理积压的消息
2. **pending_update_count**：这个数字会逐渐减少，说明 Telegram 正在处理之前积压的 322 条消息
3. **如果仍有错误**：
   - 等待 5-10 分钟后再检查
   - 确认 webhook 端点返回正确的响应（200 或 404 都可以，只要不是 SSL 错误）

## 故障排除

### 如果 webhook 仍然显示 SSL 错误

```bash
# 1. 确认证书链完整
openssl s_client -connect telegram8.org:443 -servername telegram8.org < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -A 5 "Issuer"

# 2. 检查证书是否被正确使用
openssl s_client -connect telegram8.org:443 -servername telegram8.org < /dev/null 2>&1 | grep -E "(Verify return code|Certificate chain)"

# 3. 等待更长时间（Telegram 可能需要 10-15 分钟来更新）
# 然后再次检查
curl -s "https://api.telegram.org/bot7143616257:AAHW5qyCl_alnWk3MMZaNdqBWnp3inzQVho/getWebhookInfo"
```

### 如果 webhook 端点返回错误

```bash
# 检查 webhook 端点
curl -v https://telegram8.org/telegram/notes/JizhangARLBot

# 检查应用日志（根据您的应用框架）
# 如果是 webman，检查日志文件
tail -f /path/to/webman/runtime/logs/*.log
```

## 完成检查清单

- [x] 证书已正确安装（有效期到 2026-03-19）
- [x] nginx 正常运行
- [x] HTTPS 访问正常（200 OK）
- [ ] 在线证书验证通过
- [ ] webhook 端点可访问
- [ ] Telegram webhook 重新设置
- [ ] webhook 状态无错误
- [ ] 积压消息开始处理

