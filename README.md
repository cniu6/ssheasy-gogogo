# SSHEasy - 基于浏览器的 SSH/SFTP 客户端

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Go Report Card](https://goreportcard.com/badge/github.com/cniu6/ssheasy-gogogo)](https://goreportcard.com/report/github.com/cniu6/ssheasy-gogogo)

在线 SSH、SFTP 客户端 [ssheasy.com](https://ssheasy.com) 的源代码仓库。

**[English Documentation / 英文文档](README_EN.md)**

## 📖 目录

- [简介](#简介)
- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [构建和运行](#构建和运行)
- [使用说明](#使用说明)
- [配置选项](#配置选项)
- [项目结构](#项目结构)
- [高级功能](#高级功能)
- [测试](#测试)
- [常见问题](#常见问题)
- [贡献指南](#贡献指南)
- [许可证](#许可证)

## 简介

SSHEasy 是一个完全在浏览器中运行的 SSH/SFTP 客户端，无需安装任何软件即可从任何地方连接到您的服务器。它使用 WebAssembly 技术将 Go 语言编写的 SSH/SFTP 客户端编译为 WASM，通过 WebSocket 代理实现浏览器与远程服务器的安全连接。

### 为什么选择 SSHEasy？

- ✅ **零安装**：直接在浏览器中运行，无需安装任何客户端软件
- ✅ **安全可靠**：所有凭证信息仅在浏览器中处理，不会传输到我们的服务器
- ✅ **功能完整**：支持 SSH 终端和 SFTP 文件管理
- ✅ **跨平台**：支持 Windows、macOS、Linux 等所有主流操作系统
- ✅ **多种认证方式**：支持密码、私钥和 WebAuthn 认证

## 功能特性

### 核心功能
- 🖥️ **SSH 终端**：完整的 SSH 终端模拟，支持命令行操作
- 📁 **SFTP 文件浏览器**：可视化文件管理界面，支持上传、下载、重命名等操作
- 🔐 **多种认证方式**：
  - 密码认证
  - SSH 私钥认证（支持加密私钥）
  - WebAuthn 生物识别认证（指纹、Face ID 等）
- 🔍 **终端搜索**：在终端历史中搜索文本
- 💾 **会话历史**：自动保存连接历史，快速重连
- 📥 **历史下载**：导出终端会话历史记录
- 🖼️ **全屏模式**：支持终端全屏显示

### 技术特点
- 基于 WebAssembly (WASM) 技术
- 使用 Xterm.js 提供终端体验
- WebSocket 隧道代理 TCP 连接
- 前后端分离架构
- 支持 Docker 容器化部署

## 快速开始

### 方法一：使用预编译二进制文件（推荐）

1. 从 [Releases](https://github.com/cniu6/ssheasy-gogogo/releases) 页面下载对应平台的二进制文件

2. 运行程序：
```bash
# Linux/macOS
chmod +x ssheasy
./ssheasy -port 8080

# Windows
ssheasy.exe -port 8080
```

3. 在浏览器中打开 `http://localhost:8080/cl/`

### 方法二：使用 build.bat 自动构建（Windows）

项目提供了自动化构建脚本，一键完成所有构建步骤：

```bash
# 运行构建脚本
build.bat

# 或指定平台
build.bat windows  # 构建 Windows 版本
build.bat linux    # 构建 Linux 版本
```

构建脚本会自动：
- 安装必要的依赖（xterm.js 及相关插件）
- 编译 WebAssembly 模块
- 构建代理服务器
- 生成可执行文件

### 方法三：从源码构建

#### 前置要求
- Go 1.19 或更高版本
- Node.js 和 npm（用于安装前端依赖）
- Git

#### 构建步骤

1. **克隆仓库**
```bash
git clone https://github.com/cniu6/ssheasy-gogogo.git
cd ssheasy-gogogo
```

2. **安装前端依赖**
```bash
cd web1/html
npm install @xterm/xterm @xterm/addon-fit @xterm/addon-search @xterm/addon-web-links @xterm/addon-serialize
cd ../..
```

3. **编译 WebAssembly 模块**
```bash
cd web1
GOOS=js GOARCH=wasm go build -o html/main.wasm
# 复制 wasm_exec.js
cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" html/
cd ..
```

4. **构建代理服务器**
```bash
cd proxy
go build -o ssheasy
cd ..
```

5. **运行服务**
```bash
./proxy/ssheasy -port 8080
```

6. **访问应用**
在浏览器中打开 `http://localhost:8080/cl/`

## 构建和运行

### 开发环境设置

使用 Docker Compose 可以快速搭建完整的开发环境：

```bash
docker-compose up
```

这将启动：
- WASM SSH/SFTP 客户端编译环境
- WebSocket 代理服务
- Nginx Web 服务器
- Prometheus + Grafana 监控系统
- 测试用 SSHD 服务器

启动后访问 `http://localhost:8080`

### 生产环境部署

#### 使用 Docker

```bash
# 构建镜像
docker build -t ssheasy .

# 运行容器
docker run -d -p 8080:5555 ssheasy
```

#### 使用 Systemd（Linux）

创建服务文件 `/etc/systemd/system/ssheasy.service`：

```ini
[Unit]
Description=SSHEasy Web SSH Client
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/ssheasy
ExecStart=/opt/ssheasy/ssheasy -port 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable ssheasy
sudo systemctl start ssheasy
```

## 使用说明

### 基本连接

1. 在浏览器中打开 SSHEasy
2. 填写连接信息：
   - 用户名
   - 主机地址
   - 端口（默认 22）
   - 密码或私钥
3. 点击"连接"按钮
4. 首次连接时会显示服务器指纹，确认后即可连接

### URL 快速连接功能

SSHEasy 支持通过 URL 参数自动填充连接信息并直接连接到 SSH 服务器，方便快速访问和集成到其他系统。

#### 支持的 URL 格式

以下所有格式均支持：

**格式 1：使用 `/cl/connect` 路径（推荐）**
```
http://localhost:8080/cl/connect?host=192.168.1.100&port=22&user=admin&password=admin123
```

**格式 2：使用 `/cl/` 根路径**
```
http://localhost:8080/cl/?host=192.168.1.100&port=22&user=admin&password=admin123
```

**格式 3：使用 `/connect` 路径**
```
http://localhost:8080/connect?host=192.168.1.100&port=22&user=admin&password=admin123
```

#### URL 参数说明

##### 必需参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `host` | SSH 服务器地址（IP 或域名） | `192.168.1.100` 或 `example.com` |
| `user` | SSH 用户名 | `root`, `admin`, `ubuntu` |

##### 可选参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|---------|------|
| `port` | SSH 端口 | `22` | `2222` |
| `password` | SSH 密码 | 无 | `mypassword` |
| `pk` | SSH 私钥内容（字符串） | 无 | `-----BEGIN RSA...` |
| `webauthnKey` | WebAuthn 密钥 ID | `-1` | `0`, `1` |
| `connect` | 是否自动连接 | `true` | `true` 或 `false` |

#### 使用示例

**示例 1：基本连接（密码认证）**
```
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&password=mypassword
```
这将自动填充主机、用户名和密码，并立即连接到服务器。

**示例 2：指定端口**
```
http://localhost:8080/cl/connect?host=example.com&port=2222&user=admin&password=admin123
```

**示例 3：仅填充信息，不自动连接**
```
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&password=mypassword&connect=false
```
这将填充连接表单，但不会自动连接，等待用户点击"连接"按钮。

**示例 4：使用 WebAuthn**
```
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&webauthnKey=0
```
前提：已经在浏览器中创建了 WebAuthn 密钥，并且密钥索引为 0。

**示例 5：URL 编码的密码**

如果密码包含特殊字符，需要进行 URL 编码：

```javascript
// JavaScript 中编码
const password = "p@ss#word!";
const encodedPassword = encodeURIComponent(password);
const url = `http://localhost:8080/cl/connect?host=192.168.1.100&user=root&password=${encodedPassword}`;
```

生成的 URL：
```
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&password=p%40ss%23word!
```

#### 安全注意事项

##### ⚠️ 重要警告

1. **不要在 URL 中包含密码**（公共环境）
   - URL 会被记录在浏览器历史中
   - URL 可能被代理服务器记录
   - URL 可能被分享时泄露

2. **推荐的安全做法**
   - 仅在本地网络或受信任的环境中使用
   - 优先使用 SSH 密钥认证
   - 使用 `connect=false` 参数，让用户手动输入密码
   - 使用 HTTPS（如果部署到公网）

##### 安全示例

**不安全（密码在 URL 中）：**
```
http://localhost:8080/cl/connect?host=production.com&user=root&password=secretpass123
```

**安全（仅预填主机和用户）：**
```
http://localhost:8080/cl/connect?host=production.com&user=root&connect=false
```
用户需要手动输入密码并点击"连接"。

#### 实际应用场景

**场景 1：快速访问链接**

创建书签或快捷方式：
```
http://localhost:8080/cl/connect?host=dev-server&user=developer&connect=false
```
点击书签即可快速打开 SSH 连接页面。

**场景 2：文档中的链接**

在内部文档中添加直达链接：
```markdown
## 开发服务器
[连接到开发服务器](http://localhost:8080/cl/connect?host=dev.internal&user=devuser&connect=false)
```

**场景 3：监控脚本生成的链接**

监控系统检测到问题时，生成带服务器信息的链接：
```python
def generate_ssh_link(host, user):
    base_url = "http://ssheasy.company.com/cl/connect"
    return f"{base_url}?host={host}&user={user}&connect=false"

# 使用
link = generate_ssh_link("problem-server-01", "admin")
send_alert(f"Server issue detected. Quick SSH access: {link}")
```

#### 动态生成连接 URL

**JavaScript 示例：**
```javascript
function createSSHLink(host, user, port = 22, autoConnect = false) {
  const params = new URLSearchParams({
    host: host,
    user: user,
    port: port,
    connect: autoConnect.toString()
  });

  return `http://localhost:8080/cl/connect?${params.toString()}`;
}

// 使用
const link = createSSHLink("192.168.1.100", "admin", 22, false);
console.log(link);
// 输出: http://localhost:8080/cl/connect?host=192.168.1.100&user=admin&port=22&connect=false
```

**Python 示例：**
```python
from urllib.parse import urlencode

def create_ssh_link(host, user, port=22, auto_connect=False):
    base_url = "http://localhost:8080/cl/connect"
    params = {
        'host': host,
        'user': user,
        'port': port,
        'connect': 'true' if auto_connect else 'false'
    }
    return f"{base_url}?{urlencode(params)}"

# 使用
link = create_ssh_link("192.168.1.100", "admin")
print(link)
```

### 使用私钥认证

1. 点击"选择密钥文件"按钮
2. 选择您的私钥文件（通常是 `~/.ssh/id_rsa`）
3. 如果私钥有密码保护，在密码框中输入密钥密码
4. 点击"连接"

### 使用 WebAuthn 认证

WebAuthn 支持使用生物识别设备（如指纹识别器、Face ID、YubiKey 等）进行认证。

#### 创建 WebAuthn 密钥

1. 点击"创建 Webauthn 密钥"
2. 输入密钥名称
3. 选择密钥类型：
   - **Platform（平台密钥）**：存储在当前设备/浏览器中
   - **Cross-platform（跨平台密钥）**：存储在外部设备（如 YubiKey）中
4. 按照浏览器提示完成生物识别验证
5. 复制显示的公钥到服务器的 `~/.ssh/authorized_keys` 文件中

#### 使用 WebAuthn 连接

1. 在下拉菜单中选择已创建的 WebAuthn 密钥
2. 填写其他连接信息
3. 点击"连接"
4. 按照浏览器提示完成生物识别验证

### 文件浏览器操作

连接成功后，可以点击"显示文件浏览器"按钮打开 SFTP 文件管理界面。

**注意：** 文件浏览器现在从根目录（`/`）开始，允许您浏览整个文件系统（在用户权限范围内）。

支持的操作：
- 📂 浏览目录（从根目录开始）
- 📤 上传文件
- 📥 下载文件
- ✏️ 重命名文件/目录
- 🗑️ 删除文件/目录
- ➕ 创建新目录
- ✂️ 复制/移动文件

#### 文件浏览器功能说明

1. **根目录访问**：文件浏览器默认从根目录（`/`）开始，您可以访问用户权限范围内的所有目录
2. **路径导航**：点击路径中的任意部分可快速跳转到该目录
3. **批量操作**：支持选择多个文件进行批量下载或删除
4. **拖拽上传**：支持拖拽文件到浏览器窗口进行上传
5. **权限管理**：显示文件权限信息，提醒用户注意访问权限

## 配置选项

### 命令行参数

独立二进制文件支持以下命令行选项：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-port <number>` | 设置监听端口 | 5555 |
| `-pub <address>` | 设置公共监听地址 | ":5555" |
| `-priv <address>` | 设置管理监听地址 | ":6666" |
| `-adm-key <key>` | 设置管理 API 密钥 | – |
| `-al <file>` | 设置审计日志文件 | "connections.log" |

**示例：**
```bash
# 在 8080 端口启动
./ssheasy -port 8080

# 指定公共和管理地址
./ssheasy -pub "0.0.0.0:8080" -priv "127.0.0.1:8081"

# 启用审计日志
./ssheasy -port 8080 -al "/var/log/ssheasy/audit.log"
```

### 代理模式

SSHEasy 支持两种代理模式：

#### 1. 默认模式（推荐）
通过 SSHEasy 服务器代理所有连接，适合大多数场景。

#### 2. 旁路模式
勾选"旁路代理"选项，直连目标服务器。此模式下：
- 目标地址需要运行 WebSocket 代理（如 websockify）
- 不经过 SSHEasy 服务器中转
- 适合内网环境或自建代理场景

## 项目结构

```
ssheasy-gogogo/
├── proxy/                  # WebSocket 代理服务器
│   ├── main.go            # 主程序入口
│   ├── fileserver.go      # 静态文件服务
│   └── ...
├── web1/                   # WebAssembly SSH/SFTP 客户端
│   ├── main.go            # WASM 主程序
│   ├── browser.go         # 文件浏览器实现
│   ├── webauth.go         # WebAuthn 认证
│   └── html/              # 前端文件
│       ├── index.html     # 主页面
│       ├── browser.html   # 文件浏览器页面
│       └── assets/        # 静态资源
├── nginx/                  # Nginx 配置和 Dockerfile
├── build.bat              # Windows 自动构建脚本
├── docker-compose.yml     # Docker Compose 配置
└── README.md              # 本文档
```

### 主要组件说明

#### proxy/ - WebSocket 代理服务
- 提供 WebSocket 到 TCP 的隧道代理
- 静态文件服务器
- 管理 API 接口
- 连接审计日志

#### web1/ - WASM 客户端
- SSH 客户端实现（基于 golang.org/x/crypto/ssh）
- SFTP 客户端实现
- WebAuthn 认证支持
- 浏览器 API 集成

#### web1/html/ - 前端界面
- 基于 Xterm.js 的终端界面
- 文件浏览器 UI（基于 Angular Filemanager）
- WebAuthn 密钥管理
- 连接历史管理

## 高级功能

### 连接历史管理

SSHEasy 自动保存连接历史记录（存储在浏览器 LocalStorage 中）：
- 自动保存成功的连接配置
- 快速重连历史服务器
- 删除不需要的历史记录

### 终端搜索

在终端中查找文本：
1. 在"查找"输入框中输入搜索文本
2. 勾选"区分大小写"选项（可选）
3. 点击"查找下一个"或"查找上一个"

### 会话历史导出

点击"下载"按钮可以将当前终端会话历史导出为文本文件，便于保存操作记录。

### 全屏模式

点击"切换全屏"按钮可以让终端进入全屏模式，提供更好的操作体验。按 `ESC` 键退出全屏。

## 测试

### 本地测试

使用 Docker Compose 启动测试环境：

```bash
docker-compose up
```

测试连接信息：
- 主机：`testssh`
- 端口：`22`
- 用户名：`root`
- 密码：`root`

### WebAuthn 测试

1. 启动项目并创建 WebAuthn 密钥
2. 复制显示的公钥到 `ssh_conf/authorized_keys` 文件
3. 如果未启动，启动 testopenssh 服务：
   ```bash
   docker-compose up testopenssh
   ```
4. 使用以下信息连接：
   - 用户名：`linuxserver.io`
   - 主机：`testopenssh`
   - 端口：`2222`
   - 认证：选择创建的 WebAuthn 密钥

## 常见问题

### Q: 连接失败，显示 "cannot connect to host"

**A:** 请检查：
1. 目标服务器是否在线且可访问
2. SSH 端口是否正确（默认 22）
3. 防火墙是否允许 SSH 连接
4. 如果使用旁路模式，确保目标服务器运行了 WebSocket 代理

### Q: 私钥认证失败

**A:** 请确认：
1. 私钥格式正确（支持 OpenSSH 和 PEM 格式）
2. 如果私钥有密码保护，确保输入了正确的密钥密码
3. 公钥已添加到服务器的 `~/.ssh/authorized_keys` 文件中
4. 服务器的 `~/.ssh` 目录权限正确（700）

### Q: WebAuthn 不可用

**A:** WebAuthn 需要：
1. HTTPS 连接（或 localhost）
2. 支持 WebAuthn 的现代浏览器
3. 支持的生物识别设备或安全密钥

### Q: 文件浏览器无法打开

**A:** 文件浏览器需要：
1. SFTP 子系统在服务器上可用
2. 用户有访问文件系统的权限
3. 浏览器允许 iframe 加载

### Q: 快速连接 URL 返回 404 错误

**A:** 如果使用快速连接 URL（如 `/cl/connect?host=...`）时遇到 404 错误：
1. 确保使用最新版本的 SSHEasy（v2.2 或更高版本）
2. 清除浏览器缓存（Ctrl+Shift+R 或 Cmd+Shift+R）
3. 确认 URL 格式正确（推荐使用 `/cl/connect` 路径）
4. 检查代理服务器是否正确编译和启动

**技术说明：** 快速连接功能依赖 SPA（单页应用）路由支持，早期版本可能不支持此功能。

### Q: 如何提高安全性？

**A:** 建议：
1. 使用 SSH 密钥认证而非密码
2. 启用 WebAuthn 认证
3. 配置服务器禁用密码认证
4. 使用防火墙限制访问
5. 启用审计日志监控连接

## 贡献指南

欢迎贡献代码、报告问题和提出建议！

### 如何贡献

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

### 报告问题

在 [Issues](https://github.com/cniu6/ssheasy-gogogo/issues) 页面报告问题，请包含：
- 详细的问题描述
- 复现步骤
- 预期行为和实际行为
- 环境信息（浏览器、操作系统等）

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- [Xterm.js](https://xtermjs.org/) - 终端模拟器
- [golang.org/x/crypto/ssh](https://pkg.go.dev/golang.org/x/crypto/ssh) - Go SSH 库
- [angular-filemanager](https://github.com/joni2back/angular-filemanager) - 文件管理器 UI

## 联系方式

- 项目主页：[https://github.com/cniu6/ssheasy-gogogo](https://github.com/cniu6/ssheasy-gogogo)
- 在线演示：[https://ssheasy.com](https://ssheasy.com)
- 问题反馈：[GitHub Issues](https://github.com/cniu6/ssheasy-gogogo/issues)

---

**注意：** 本项目仅用于学习和合法用途。请遵守相关法律法规，不要用于未经授权的访问。
