# SSHEasy - 浏览器中的 SSH/SFTP 客户端

基于 WebAssembly 的在线 SSH、SFTP 客户端，可直接在浏览器中运行。

## 特性

- ✨ 纯浏览器运行，无需安装任何软件
- 🔒 安全加密连接，凭据不经过服务器
- 📁 内置文件浏览器，支持 SFTP 文件管理
- 🌐 支持 WebAuthn 密钥认证
- 🚀 使用 Go 编译为 WebAssembly，性能优异
- 📦 单个可执行文件，资源内嵌，开箱即用

## 快速开始

### 方式一：直接运行可执行文件

1. 下载或编译可执行文件
2. 运行程序：
   ```bash
   # Windows
   .\proxy.exe -port 8080

   # Linux/Mac
   ./proxy -port 8080
   ```
3. 在浏览器中打开 `http://localhost:8080/cl/`

### 方式二：使用 Docker Compose（完整开发环境）

```bash
docker-compose up
```

这将启动完整的开发环境，包括：
- WebAssembly SSH/SFTP 客户端编译
- WebSocket 代理服务
- Nginx 前端服务器
- Prometheus 和 Grafana 监控
- 测试用 SSH 服务器

启动后访问 `http://localhost:8080`

## 编译

### 编译 Go 服务端

```bash
cd proxy
go build -o ssheasy.exe
```

### 编译 WebAssembly 客户端

```bash
cd web
GOOS=js GOARCH=wasm go build -o html/main.wasm
```

## 使用说明

### 命令行参数

```bash
ssheasy [选项]
```

**主要参数：**
- `-port <端口号>` - 设置监听端口（默认：5555）
- `-pub <地址>` - 设置公共监听地址（默认：":5555"）
- `-priv <地址>` - 设置管理监听地址（默认：":6666"）
- `-adm-key <密钥>` - 设置管理 API 密钥
- `-al <文件路径>` - 设置连接审计日志文件（默认："connections.log"）

**使用示例：**

```bash
# 使用默认端口 5555
./ssheasy

# 指定端口 8080
./ssheasy -port 8080

# 完整参数
./ssheasy -port 8080 -priv :9090 -al /var/log/ssh-connections.log
```

### 连接到 SSH 服务器

1. 打开浏览器访问 `http://localhost:端口号/cl/`
2. 填写连接信息：
   - **用户名**：SSH 用户名（默认：root）
   - **主机地址**：SSH 服务器地址
   - **端口**：SSH 端口（默认：22）
   - **密码/密钥口令**：SSH 密码或私钥口令
   - **私钥**：可选，SSH 私钥内容
3. 点击"连接"按钮
4. 确认服务器指纹后即可使用

### URL 自动连接

支持通过 URL 参数自动填充连接信息并连接：

```
http://localhost:8080/cl/connect?host=服务器地址&port=22&user=用户名&password=密码
```

**URL 参数说明：**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `host` | SSH 服务器地址 | - |
| `port` | SSH 服务器端口 | 22 |
| `user` | SSH 用户名 | - |
| `password` | SSH 密码 | - |
| `pk` | 私钥内容（字符串） | - |
| `webauthnKey` | WebAuthn 密钥 ID | -1 |
| `connect` | 是否自动连接（"true"/"false"） | "true" |

**示例：**
```
# 自动连接
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&password=mypassword

# 仅填充信息，不自动连接
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&connect=false
```

### WebAuthn 密钥认证

1. 点击"创建 Webauthn 密钥"
2. 输入密钥名称，选择密钥类型
3. 按照浏览器提示创建密钥
4. 将生成的公钥添加到服务器的 `~/.ssh/authorized_keys` 文件
5. 连接时选择对应的 WebAuthn 密钥

## 项目结构

```
ssheasy-gogogo/
├── proxy/              # Go WebSocket 代理服务
│   ├── main.go        # 主程序（支持资源内嵌和 -port 参数）
│   ├── admin.go       # 管理接口
│   └── fileserver.go  # 文件服务器
├── web/               # WebAssembly SSH/SFTP 客户端
│   ├── html/          # 前端页面（中文界面）
│   │   ├── index.html # 主页面
│   │   ├── browser.html # 文件浏览器
│   │   └── webauthn.html # WebAuthn 说明
│   └── main.go        # WASM 客户端源码
├── nginx/             # Nginx 配置
├── docker-compose.yaml # Docker 编排配置
└── README_CN.md       # 中文说明文档
```

## 安全说明

- 所有 SSH 凭据仅在浏览器和目标服务器之间传输
- 代理服务器仅转发加密的数据包，无法访问明文信息
- 与使用 OpenSSH 客户端相同的安全级别
- 支持 SSH 密钥认证和 WebAuthn 硬件密钥

## 测试环境

使用 Docker Compose 启动后，可以使用内置的测试 SSH 服务器：

- **主机**：testssh
- **端口**：22
- **用户名**：root
- **密码**：root

## WebAuthn 测试

1. 创建 WebAuthn 密钥
2. 将显示的公钥复制到 `ssh_conf/authorized_keys` 文件
3. 启动 testopenssh 服务（如果尚未启动）
4. 连接信息：
   - **主机名**：testopenssh
   - **端口**：2222
   - **用户名**：linuxserver.io

## 技术栈

- **后端**：Go 1.16+
- **前端**：WebAssembly、Xterm.js、Bootstrap 4
- **SSH/SFTP**：golang.org/x/crypto/ssh
- **文件管理器**：Angular Filemanager (fork)

## 许可证

本项目基于原始 [ssheasy](https://github.com/hullarb/ssheasy) 项目修改。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v2.0（本版本）
- ✨ 界面完全汉化
- 📦 实现资源内嵌，单文件部署
- 🔧 添加 `-port` 命令行参数
- 🚀 使用国内 CDN 优化加载速度
- 🎯 默认用户名设置为 root
- 📝 添加中文文档

---

**作者**: 原作者 Bela Hullar | 汉化和改进：当前版本

**联系方式**: info@webssh.com
