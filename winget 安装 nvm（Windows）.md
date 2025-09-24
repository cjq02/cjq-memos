## Windows 使用 winget 安装 nvm（Node Version Manager for Windows）

### 前置条件
- 使用“以管理员身份运行”的 PowerShell。
- 确认 `winget` 可用：

```powershell
winget --version
```

> 说明：若出现“搜索源时失败：msstore”，通常是微软商店源异常，不影响从社区源安装。

### 安装 nvm-windows（Corey Butler 版本）

```powershell
winget install --id CoreyButler.NVMforWindows -e --source winget
```

安装完成后，重开 PowerShell（或注销/重启）使环境变量生效，然后验证：

```powershell
nvm version
```

### 常用操作

- 查看已安装/可安装版本：

```powershell
nvm list
nvm list available
```

- 安装并切换 Node 版本：

```powershell
nvm install 20.17.0
nvm use 20.17.0
node -v
npm -v
```

- （可选）设置国内镜像加速：

```powershell
nvm node_mirror https://npmmirror.com/mirrors/node/
nvm npm_mirror  https://npmmirror.com/mirrors/npm/
```

### 处理 msstore 源报错（可选）
不影响 nvm 安装，如需处理可执行：

```powershell
winget source update
winget source disable msstore
```

### 卸载 nvm

```powershell
winget uninstall CoreyButler.NVMforWindows
```

### 常见问题

- `nvm` 命令未识别：
  - 重开终端或注销/重启；
  - 检查用户 PATH 是否包含 `C:\Users\<用户名>\AppData\Roaming\nvm`；
  - 确保 `C:\Program Files\nodejs` 由 nvm 管理（nvm 切换版本会更新该目录）。

- 已装独立版 Node 与 nvm 冲突：
  - 建议先卸载独立版 Node.js，避免 PATH 冲突；
  - 或手动清理残留 PATH 中的旧 Node 路径。

### 参考
- 包 ID：`CoreyButler.NVMforWindows`
- 源：`winget`


