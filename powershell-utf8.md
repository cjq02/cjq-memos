## PowerShell 下使用 UTF-8 与生成 Markdown 文件（UTF-8）

### 持久设定 UTF-8（当前用户）
```powershell
if (!(Test-Path $PROFILE.CurrentUserAllHosts)) {
  New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force | Out-Null
}
@'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding']    = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
'@ | Add-Content -Path $PROFILE.CurrentUserAllHosts -Encoding utf8

# 生效：重新打开 PowerShell，或执行
. $PROFILE.CurrentUserAllHosts
```

### 单次会话快速设定
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

### 生成新的 Markdown（UTF-8 无 BOM）
- 一行命令新建并写入内容：
```powershell
Set-Content -Path .\README-UTF8.md -Value "# 标题`n内容示例" -Encoding utf8
```

- 追加内容：
```powershell
Add-Content -Path .\README-UTF8.md -Value "`n## 新小节`n追加的内容" -Encoding utf8
```

- 使用模板变量生成：
```powershell
$md = @"
# 项目说明

## 环境
- Windows 10 / PowerShell 7

## 用法
1. 步骤一
2. 步骤二
"@
Set-Content .\GUIDE.md $md -Encoding utf8
```

### 使用 Out-File（同样指定编码）
```powershell
"# 日志" | Out-File .\LOG.md -Encoding utf8
```

### VS Code 配置建议
在 VS Code 设置中搜索并设置：
- Files: Encoding -> utf8
- Files: Auto Guess Encoding -> 勾选

### 备注
- 旧控制台程序若仍乱码，可临时设置：
```powershell
chcp 65001 | Out-Null
```


