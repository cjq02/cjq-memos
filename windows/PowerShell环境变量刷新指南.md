# PowerShell环境变量刷新指南

## 问题背景
当使用winget安装新程序（如PHP）后，新程序的路径会被添加到系统PATH环境变量中，但当前PowerShell会话无法识别新安装的程序。

## 解决方案

### 方法1：手动刷新环境变量
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
```

**命令解释：**
- `$env:PATH` - PowerShell中访问PATH环境变量
- `[System.Environment]::GetEnvironmentVariable("PATH","Machine")` - 获取系统级PATH
- `[System.Environment]::GetEnvironmentVariable("PATH","User")` - 获取用户级PATH
- `+ ";" +` - 用分号连接两个PATH值

### 方法2：创建自定义函数
在当前会话中定义函数：
```powershell
function refreshenv { $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User") }
```

然后使用：
```powershell
refreshenv
```

### 方法3：永久保存函数到PowerShell配置文件

#### 3.1 检查配置文件是否存在
```powershell
Test-Path $PROFILE
```

#### 3.2 创建配置文件（如果不存在）
```powershell
New-Item -Path $PROFILE -Type File -Force
```

#### 3.3 添加函数到配置文件
```powershell
Add-Content $PROFILE "function refreshenv { `$env:PATH = [System.Environment]::GetEnvironmentVariable(`"PATH`",`"Machine`") + `";`" + [System.Environment]::GetEnvironmentVariable(`"PATH`",`"User`") }"
```

#### 3.4 重新加载配置文件
```powershell
. $PROFILE
```

### 方法4：重启PowerShell
最简单的方法就是关闭当前PowerShell窗口，重新打开一个新的。

## 查看自定义函数

### 查看所有函数
```powershell
Get-Command -CommandType Function
```

### 查看用户自定义函数
```powershell
Get-Command -CommandType Function | Where-Object { $_.Source -eq $null }
```

### 查看特定函数定义
```powershell
Get-Content Function:\refreshenv
```

## 常见错误

### ❌ 错误示例
```powershell
$ $env:PATH = ...  # 前面多了$符号
```

### ✅ 正确示例
```powershell
$env:PATH = ...  # 前面没有$符号
```

## 验证环境变量是否生效

### 检查PATH环境变量
```powershell
$env:PATH
```

### 测试新安装的程序
```powershell
php --version
```

## 为什么需要刷新环境变量？

1. **安装新程序时**：程序路径被添加到系统PATH
2. **当前会话问题**：PowerShell会话使用的是旧的PATH值
3. **刷新作用**：重新加载最新的PATH到当前会话
4. **类比**：就像新装电器后需要重新打开电闸

## 推荐使用流程

1. 安装新程序（如：`winget install PHP.PHP.8.1`）
2. 刷新环境变量：`refreshenv` 或手动执行刷新命令
3. 验证程序可用：`php --version`
4. 开始使用新程序

## 注意事项

- `refreshenv` 不是Windows内置命令，需要自定义
- 环境变量刷新只对当前PowerShell会话有效
- 重启PowerShell会自动加载最新的环境变量
- 配置文件中的函数需要重新加载才能在当前会话中使用
