## Windows 上使用 jabba 安装并管理 JDK 1.8（含问题排查）

本文档适用于 Windows 10/11 的 PowerShell 环境，指导通过 jabba 安装并设置 JDK 1.8 为默认版本，并给出常见问题的处理方法。

### 前置条件
- 已安装 PowerShell（系统自带）。
- 建议以“以管理员身份运行”启动 PowerShell（可减少权限相关报错）。

### 1. 配置执行策略（解决脚本禁止运行）
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### 2. 安装 jabba

- 推荐：使用官方脚本（winget 可能无包或在某些环境不可用）
```powershell
iwr -useb https://github.com/shyiko/jabba/raw/master/install.ps1 | iex
jabba --version
```

- 如果你要尝试 winget（有些环境不可用）：
```powershell
winget install --id Shyiko.jabba -e --source winget --accept-package-agreements --accept-source-agreements
```

### 3. 初始化 jabba 到 PowerShell 配置
确保打开新终端时自动加载 jabba：
```powershell
if (-not (Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force | Out-Null }
$jabbaInit = '$env:JABBA_HOME="$HOME\.jabba"; $jabbaBin=Join-Path $env:JABBA_HOME "bin"; if (-not ($env:Path -split ";" | ForEach-Object { $_.TrimEnd("\") } | Where-Object { $_ -eq $jabbaBin })) { $env:Path = "$jabbaBin;$env:Path" }; if (Test-Path (Join-Path $env:JABBA_HOME "jabba.ps1")) { . (Join-Path $env:JABBA_HOME "jabba.ps1") }'
if (-not (Get-Content $PROFILE | Select-String -SimpleMatch 'jabba.ps1')) { Add-Content $PROFILE "`n# jabba init`n$jabbaInit`n" }
. $PROFILE
```

验证：
```powershell
jabba --version
```

### 4. 安装 JDK 1.8（推荐 Zulu 发行版）
列出可用 1.8 版本（可选）：
```powershell
jabba ls-remote | findstr 1.8
```

安装（任选其一）：
```powershell
# Zulu（示例最终解析为 zulu@1.8.282）
jabba install zulu@1.8

# 或 Temurin
# jabba install temurin@1.8
```

切换到 JDK 1.8：
```powershell
jabba use zulu@1.8
```

如需设为默认（两种方式，择一）：
```powershell
# 方式 A：别名为 default（部分环境会因符号链接权限或解析问题失败）
jabba alias default zulu@1.8

# 方式 B：在 profile 中显式使用解析后的具体版本（稳定可靠）
. "$env:JABBA_HOME\jabba.ps1"
$jdk = (jabba which zulu@1.8)  # 例如 C:\Users\<user>\.jabba\jdk\zulu@1.8.282
$ver = Split-Path $jdk -Leaf    # 例如 zulu@1.8.282

$lines = @()
if (Test-Path $PROFILE) { $lines = Get-Content $PROFILE }
$lines = $lines | Where-Object { $_ -notmatch 'jabba use default' }
if (-not ($lines -match '\. .*jabba\.ps1')) { $lines += ". $env:JABBA_HOME\jabba.ps1" }
if (-not ($lines -match ('jabba use ' + [regex]::Escape($ver)))) { $lines += ('jabba use ' + $ver) }
Set-Content -Path $PROFILE -Value $lines -Encoding UTF8
. $PROFILE
```

### 5. 验证
```powershell
jabba current
& "$env:JAVA_HOME\bin\java.exe" -version
echo $env:JAVA_HOME
```

预期输出类似：
```
zulu@1.8.282
openjdk version "1.8.0_282"
OpenJDK Runtime Environment (Zulu 8.52.0.23-CA-win64) (build 1.8.0_282-b08)
OpenJDK 64-Bit Server VM (Zulu 8.52.0.23-CA-win64) (build 25.282-b08, mixed mode)
```

### 6. 常见问题
- 符号链接失败（权限不足）
  - 现象：`symlink ... A required privilege is not held by the client.`
  - 处理：使用“方式 B”在 profile 中显式 `jabba use zulu@<具体版本>`，无需依赖符号链接。

- `jabba use default` 出现 panic（semver 解析）
  - 现象：`panic: runtime error: index out of range`（解析 default 时触发）
  - 处理：在 profile 中移除 `jabba use default`，改为显式的 `jabba use zulu@<具体版本>`。

- `java` 未找到
  - 处理：确认当前会话是否已 `. $PROFILE`；或通过绝对路径直接验证：
    ```powershell
    . "$env:JABBA_HOME\jabba.ps1"
    $jdk = jabba which zulu@1.8
    $env:JAVA_HOME = $jdk
    if (-not ($env:Path -split ';' | Where-Object { $_ -eq "$env:JAVA_HOME\bin" })) { $env:Path = "$env:JAVA_HOME\bin;" + $env:Path }
    & "$env:JAVA_HOME\bin\java.exe" -version
    ```

- JDK 8 不支持 `--version`
  - 使用 `java -version`（注意是单横杠）。

### 7. 版本切换与卸载
- 切换版本：
```powershell
jabba ls-remote
jabba install <发行版@版本>
jabba use <发行版@版本>
```

- 卸载某版本：
```powershell
jabba uninstall <发行版@版本>
```

### 8. 提示
- PowerShell 中请用分号 `;` 串联多条命令，避免使用 `&&`。
- 如需系统级（所有用户）生效，可将 `JAVA_HOME` 与 `%JAVA_HOME%\bin` 添加到“系统变量”的 PATH（当前文档仅配置了用户会话）。

### 9. 不依赖 jabba.ps1 的显式路径法（环境混乱时推荐）
当 `$PROFILE` 中出现错误行（如 `jabba use zulu@zulu@...`）或 `jabba.ps1` 缺失/损坏时，可直接调用 `jabba.exe` 完成安装与切换，并在配置中“显式设置” `JAVA_HOME` 与 `PATH`。

1) 安装/解析 JDK 1.8 并在当前会话生效
```powershell
& "$HOME\.jabba\bin\jabba.exe" install zulu@1.8
$jdk = & "$HOME\.jabba\bin\jabba.exe" which zulu@1.8
$env:JAVA_HOME = $jdk
if (-not ($env:Path -split ';' | Where-Object { $_ -eq "$env:JAVA_HOME\bin" })) {
  $env:Path = "$env:JAVA_HOME\bin;" + $env:Path
}
& "$env:JAVA_HOME\bin\java.exe" -version
```

2) 将上述设置持久化到当前用户 PowerShell 配置（无需 `jabba.ps1`）
```powershell
if (-not (Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force | Out-Null }
$lines = @()
$lines += '# jabba: set JAVA_HOME and PATH via resolved JDK (no jabba.ps1)'
$lines += '$env:JABBA_HOME="$HOME\.jabba"'
$lines += '$jdk = & "$env:JABBA_HOME\bin\jabba.exe" which zulu@1.8'
$lines += 'if ($jdk) {'
$lines += '  $env:JAVA_HOME = $jdk'
$lines += '  if (-not ($env:Path -split '';'' | Where-Object { $_ -eq "$env:JAVA_HOME\bin" })) {'
$lines += '    $env:Path = "$env:JAVA_HOME\bin;" + $env:Path'
$lines += '  }'
$lines += '}'
Set-Content -Path $PROFILE -Value $lines -Encoding UTF8
. $PROFILE
& "$env:JAVA_HOME\bin\java.exe" -version
```

3) 清理故障配置（可选）
```powershell
# 备份
if (Test-Path $PROFILE) { Copy-Item $PROFILE "$PROFILE.bak_fix" -Force }

# 移除常见错误行
$lines = Get-Content $PROFILE
$lines = $lines | Where-Object { ($_ -notmatch 'jabba use default') -and ($_ -notmatch 'jabba use zulu@zulu@') }
Set-Content -Path $PROFILE -Value $lines -Encoding UTF8
```

4) 若需要恢复 `jabba.ps1` 能力
```powershell
Test-Path "$HOME\.jabba\jabba.ps1"  # 不存在则重装
if (-not (Test-Path "$HOME\.jabba\jabba.ps1")) {
  Remove-Item -Recurse -Force "$HOME\.jabba"
  iwr -useb https://github.com/shyiko/jabba/raw/master/install.ps1 | iex
}
```



