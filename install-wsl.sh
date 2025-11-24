#!/bin/bash

# 快速安装脚本 - 自动安装 Node.js 和项目依赖

set -e

echo "🚀 开始安装..."

# 安装 nvm
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    echo "📦 安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# 加载 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装 Node.js
if ! command -v node &> /dev/null; then
    echo "📦 安装 Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default node
fi

# 安装 pnpm
if ! command -v pnpm &> /dev/null; then
    echo "📦 安装 pnpm..."
    npm install -g pnpm@latest
fi

# 安装项目依赖
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📦 安装项目依赖..."
pnpm install

echo ""
echo "✅ 安装完成！"
echo "运行 'pnpm dev' 启动开发服务器"

