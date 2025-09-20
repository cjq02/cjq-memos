# ngrok在Windows上的安装和使用指南

## 什么是ngrok

ngrok是一个反向代理工具，可以将本地服务器暴露到公网，让您能够通过互联网访问本地开发的应用。这对于测试、演示和开发非常有用。

## 安装ngrok

### 方法一：直接下载（推荐）

1. 访问ngrok官网：https://ngrok.com/
2. 注册一个免费账户
3. 下载Windows版本的ngrok
4. 解压到任意目录，例如：`C:\ngrok\`

### 方法二：使用包管理器

#### 使用Chocolatey
```powershell
# 安装Chocolatey（如果还没有安装）
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安装ngrok
choco install ngrok
```

#### 使用Scoop
```powershell
# 安装Scoop（如果还没有安装）
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# 安装ngrok
scoop install ngrok
```

## 配置ngrok

### 1. 获取authtoken

1. 登录ngrok官网
2. 在Dashboard中找到"Your Authtoken"
3. 复制token

### 2. 配置authtoken

```powershell
# 方法一：使用命令行配置
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE

# 方法二：手动编辑配置文件
# 配置文件位置：%USERPROFILE%\.ngrok2\ngrok.yml
# 添加以下内容：
# authtoken: YOUR_AUTHTOKEN_HERE
```

## 基本使用方法

### 1. 暴露HTTP服务

```powershell
# 暴露本地3000端口的HTTP服务
ngrok http 3000

# 暴露本地8080端口的HTTP服务
ngrok http 8080

# 指定子域名（需要付费计划）
ngrok http 3000 --subdomain=myapp
```

### 2. 暴露HTTPS服务

```powershell
# 暴露本地HTTPS服务
ngrok http https://localhost:3000
```

### 3. 暴露TCP服务

```powershell
# 暴露TCP服务
ngrok tcp 22
```

### 4. 暴露特定主机

```powershell
# 暴露特定主机的服务
ngrok http 192.168.1.100:3000
```

## 高级配置

### 1. 配置文件设置

创建配置文件 `%USERPROFILE%\.ngrok2\ngrok.yml`：

```yaml
version: "2"
authtoken: YOUR_AUTHTOKEN_HERE
tunnels:
  web:
    proto: http
    addr: 3000
    subdomain: myapp
  api:
    proto: http
    addr: 8080
    subdomain: myapi
  ssh:
    proto: tcp
    addr: 22
```

### 2. 使用配置文件启动多个隧道

```powershell
# 启动所有配置的隧道
ngrok start --all

# 启动特定隧道
ngrok start web
ngrok start web api
```

## 常用参数

```powershell
# 指定区域
ngrok http 3000 --region=us

# 指定主机头
ngrok http 3000 --host-header=localhost:3000

# 基本认证
ngrok http 3000 --basic-auth="username:password"

# 自定义域名（需要付费计划）
ngrok http 3000 --hostname=myapp.example.com

# 查看帮助
ngrok help
```

## 监控和调试

### 1. Web界面

ngrok启动后会提供一个Web界面，默认地址：http://localhost:4040

在这个界面可以：
- 查看请求历史
- 重放请求
- 查看请求/响应详情
- 修改请求头

### 2. 日志

```powershell
# 启用详细日志
ngrok http 3000 --log=stdout --log-level=debug
```

## 常见问题解决

### 1. 端口被占用

```powershell
# 查看端口占用
netstat -ano | findstr :4040

# 杀死占用进程
taskkill /PID <进程ID> /F
```

### 2. 防火墙问题

确保Windows防火墙允许ngrok通过，或者临时关闭防火墙进行测试。

### 3. 网络连接问题

```powershell
# 检查网络连接
ping ngrok.com

# 使用代理（如果需要）
ngrok http 3000 --proxy=http://proxy.company.com:8080
```

## 安全注意事项

1. **不要暴露敏感服务**：ngrok会将本地服务暴露到公网，确保不要暴露包含敏感数据的服务。

2. **使用HTTPS**：对于生产环境，建议使用HTTPS。

3. **设置访问控制**：使用基本认证或其他访问控制机制。

4. **定期更换authtoken**：定期更换您的authtoken。

## 实用技巧

### 1. 创建批处理文件

创建 `start-ngrok.bat`：

```batch
@echo off
cd /d C:\ngrok
ngrok http 3000
pause
```

### 2. 使用PowerShell脚本

创建 `Start-Ngrok.ps1`：

```powershell
param(
    [int]$Port = 3000,
    [string]$Subdomain = ""
)

if ($Subdomain) {
    ngrok http $Port --subdomain=$Subdomain
} else {
    ngrok http $Port
}
```

使用方法：
```powershell
.\Start-Ngrok.ps1 -Port 8080 -Subdomain myapp
```

### 3. 集成到开发环境

在 `package.json` 中添加脚本：

```json
{
  "scripts": {
    "tunnel": "ngrok http 3000",
    "dev": "npm start & ngrok http 3000"
  }
}
```

## 免费版限制

- 每次连接最多4小时
- 随机子域名
- 连接数限制
- 带宽限制

## 付费计划

- 固定子域名
- 自定义域名
- 更多连接数
- 更高带宽
- 24/7支持

## 总结

ngrok是一个强大的工具，可以快速将本地服务暴露到公网。通过本指南，您应该能够：

1. 安装和配置ngrok
2. 基本使用ngrok暴露服务
3. 使用高级功能和配置
4. 解决常见问题
5. 集成到开发工作流中

记住始终注意安全性，不要暴露包含敏感数据的服务到公网。
