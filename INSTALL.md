# WSL Ubuntu 环境安装指南

如果您在 WSL Ubuntu 环境中遇到 `node: not found` 错误，请按照以下步骤操作：

## 方法 1: 使用 nvm 安装 Node.js (推荐)

### 步骤 1: 安装 nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

### 步骤 2: 重新加载 shell 配置

```bash
source ~/.bashrc
# 或者
source ~/.zshrc
```

### 步骤 3: 安装 Node.js LTS 版本

```bash
nvm install --lts
nvm use --lts
nvm alias default node
```

### 步骤 4: 验证安装

```bash
node --version
npm --version
```

### 步骤 5: 安装 pnpm

```bash
npm install -g pnpm
```

### 步骤 6: 安装项目依赖

```bash
cd frontend
pnpm install
```

## 方法 2: 使用 NodeSource 仓库安装

```bash
# 更新系统
sudo apt update

# 安装 Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 验证安装
node --version
npm --version

# 安装 pnpm
npm install -g pnpm

# 安装项目依赖
cd frontend
pnpm install
```

## 方法 3: 使用 npm 代替 pnpm

如果您不想安装 pnpm，也可以使用 npm：

```bash
cd frontend
npm install
```

## 快速安装脚本（推荐）

### 方法 A: 一键安装脚本（最简单）

在 WSL 终端中运行：

```bash
cd /mnt/d/me/epiboly/fuye/projects/fuyelead/frontend
chmod +x quick-install.sh
bash quick-install.sh
```

这个脚本会自动：
- 安装 nvm（如果未安装）
- 安装 Node.js LTS 版本
- 安装 pnpm
- 安装项目所有依赖

### 方法 B: 交互式安装脚本

如果需要更多控制选项：

```bash
cd /mnt/d/me/epiboly/fuye/projects/fuyelead/frontend
chmod +x install-nodejs.sh
bash install-nodejs.sh
```

## 常见问题

### 问题: 找不到 node 命令

**解决方案**: 确保 Node.js 已正确安装并添加到 PATH

```bash
# 检查 Node.js 是否安装
which node

# 如果使用 nvm，确保已加载
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### 问题: pnpm 命令找不到

**解决方案**: 确保 pnpm 已全局安装

```bash
npm install -g pnpm
```

### 问题: 权限错误

**解决方案**: 使用 sudo 或配置 npm 全局安装路径

```bash
# 配置 npm 全局安装路径（推荐）
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 然后重新安装 pnpm
npm install -g pnpm
```

