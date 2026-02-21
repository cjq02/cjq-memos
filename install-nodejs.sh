#!/bin/bash

# WSL Ubuntu 环境安装 Node.js 和 pnpm 脚本

set -e  # 遇到错误立即退出

echo "=========================================="
echo "WSL Ubuntu 环境 Node.js 和 pnpm 安装脚本"
echo "=========================================="
echo ""

# 检查是否在 WSL 环境
if [ -f /proc/version ] && grep -q Microsoft /proc/version; then
    echo "✓ 检测到 WSL 环境"
else
    echo "⚠ 警告: 未检测到 WSL 环境，但继续执行..."
fi

echo ""
echo "步骤 1: 检查并安装 nvm..."
echo "----------------------------------------"

# 检查 nvm 是否已安装
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "✓ nvm 已安装，加载 nvm..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    echo "正在安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # 将 nvm 加载命令添加到 .bashrc（如果还没有）
    if ! grep -q "NVM_DIR" "$HOME/.bashrc"; then
        echo '' >> ~/.bashrc
        echo '# NVM Configuration' >> ~/.bashrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        echo "✓ 已将 nvm 配置添加到 ~/.bashrc"
    fi
fi

echo ""
echo "步骤 2: 安装 Node.js LTS 版本..."
echo "----------------------------------------"

# 确保 nvm 已加载
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装最新的 LTS 版本
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version)
    echo "✓ Node.js 已安装: $CURRENT_VERSION"
    echo "正在检查并更新到最新的 LTS 版本..."
        nvm install --lts
        nvm use --lts
        nvm alias default node
else
    echo "正在安装 Node.js LTS 版本..."
    nvm install --lts
    nvm use --lts
    nvm alias default node
fi

# 验证 Node.js 安装
echo ""
echo "步骤 3: 验证安装..."
echo "----------------------------------------"
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "✓ Node.js 版本: $NODE_VERSION"
echo "✓ npm 版本: $NPM_VERSION"

echo ""
echo "步骤 4: 安装 pnpm..."
echo "----------------------------------------"

# 检查 pnpm 是否已安装
if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    echo "✓ pnpm 已安装: $PNPM_VERSION"
    echo "正在更新到最新版本..."
        npm install -g pnpm@latest
else
    echo "正在安装 pnpm..."
    npm install -g pnpm@latest
fi

PNPM_VERSION=$(pnpm --version)
echo "✓ pnpm 版本: $PNPM_VERSION"

echo ""
echo "步骤 5: 安装项目依赖..."
echo "----------------------------------------"

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "当前目录: $(pwd)"

# 检查是否存在 package.json，如果存在则安装依赖
if [ -f "package.json" ]; then
    echo "检测到 package.json，正在运行: pnpm install"
echo ""
pnpm install
else
    echo "⚠ 未检测到 package.json，跳过依赖安装"
fi

echo ""
echo "=========================================="
echo "✓ 安装完成！"
echo "=========================================="
echo ""
echo "下一步:"
echo "  运行开发服务器: pnpm dev"
echo "  构建项目: pnpm build"
echo ""

