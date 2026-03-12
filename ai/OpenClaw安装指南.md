# OpenClaw 安装指南（WSL）

## 概述

OpenClaw 是一款「能干活的」AI 助手，支持接入 WhatsApp、Telegram、Discord 等聊天平台，通过自然语言执行任务。**本文档仅记录在 Windows 下通过 WSL（Windows Subsystem for Linux）的安装方式。**

**官方资源**：
- 官网：https://openclaws.io/
- 文档：https://docs.openclaw.ai/
- 仓库：https://github.com/openclaw/openclaw

---

## 系统要求

| 项目 | 要求 |
|------|------|
| **系统** | Windows 10/11，已启用 WSL2 |
| **Node.js（WSL 内）** | 22 或更高版本（推荐 LTS），最低 18+ |
| **内存** | 最低 2 GB，推荐 4 GB 及以上 |
| **磁盘** | 安装与依赖约 500 MB |
| **可选** | Python 3.10+（部分技能需要）、Git（源码编译需要） |

调用云端 AI API 需联网；使用 Ollama 跑本地模型可离线使用。

---

## 安装方式（WSL）

### 1. 安装 / 启用 WSL2

在 **Windows** 上以管理员身份打开 PowerShell，执行：

```powershell
wsl --install
```

安装完成后按提示重启。若已安装 WSL 但未用 WSL2，可执行：

```powershell
wsl --set-default-version 2
```

### 2. 在 WSL 内安装 OpenClaw

打开 WSL 终端（Ubuntu 或其他发行版），任选一种方式安装。

**方式 A：一键脚本（推荐）**

```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git
```

**方式 B：npm 全局安装**

需 WSL 内已安装 Node.js 18+（可用 [nvm](https://github.com/nvm-sh/nvm) 或 [winget 安装 nvm（Windows）](../windows/winget%20安装%20nvm（Windows）.md) 后在 WSL 里装 Node）：

```bash
npm i -g openclaw@beta
```

### 3. 运行配置向导

安装完成后在 WSL 中执行：

```bash
openclaw onboard
```

按向导完成 AI 供应商、API Key、聊天平台等配置。

---

## 验证安装

```bash
# 查看版本（如 v2026.3.8）
openclaw --version

# 环境诊断：Node 版本、依赖、配置文件、网络
openclaw doctor
```

---

## 初始配置（onboard）

安装后执行 `openclaw onboard`，按向导完成：

1. **选择 AI 供应商**：Anthropic (Claude)、OpenAI (GPT)、Google (Gemini) 或 Ollama 本地模型。
2. **添加 API Key**：从对应供应商后台复制 Key，保存在本地 `~/.openclaw/.env`。
3. **连接聊天平台**：WhatsApp（扫码）、Telegram（Bot Token）、Discord（Bot Token）等。
4. **发测试消息**：在已连接渠道给 OpenClaw 发一条消息（如「你能做什么？」）确认回复正常。

配置文件位置：`~/.openclaw/.env`，可直接编辑以切换供应商、API Key 或端口等，详见 [文档 - Configuration](https://docs.openclaw.ai/configuration)。

---

## 启动与访问

```bash
openclaw dashboard
```

Web UI 默认地址：`http://127.0.0.1:3000`（若在 `.env` 中设置 `PORT=18789` 则为 `http://127.0.0.1:18789`，以实际配置为准）。

---

## 升级

在 WSL 内按你当时的安装方式执行：

- **一键脚本安装的**：重新执行 `curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git`，或到克隆的 `openclaw` 目录执行 `git pull && pnpm install && pnpm run build`。
- **npm 安装的**：`npm update -g openclaw@latest`

发布说明：https://github.com/openclaw/openclaw/releases

---

## 故障排查

- **未安装 WSL2**：在 Windows 管理员 PowerShell 中执行 `wsl --install`，重启后再在 WSL 终端里安装 OpenClaw。
- **Node.js 版本过旧**：需 Node.js 22+，在 WSL 内执行 `node --version` 检查；用 nvm：`nvm install --lts && nvm use --lts`。
- **权限不足**：在 WSL 内命令前加 `sudo`，或使用 nvm 等免 root 安装 Node 与 OpenClaw。
- **端口占用 (EADDRINUSE)**：在 `~/.openclaw/.env` 中设置 `PORT=3001` 等其它端口，或关闭占用端口的进程。
- **API Key 无效**：确认 Key 正确且未过期，检查 `~/.openclaw/.env` 中变量名（如 `ANTHROPIC_API_KEY`、`OPENAI_API_KEY`），修改后重启 OpenClaw。

遇到问题可到 [Discord](https://discord.gg/openclaw) 或官方文档寻求帮助。

---

*文档整理自官方安装说明，便于本地备忘与查阅。*
