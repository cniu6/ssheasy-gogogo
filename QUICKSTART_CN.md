# SSHEasy 快速启动指南

## 🚀 快速开始（3步）

### 1. 下载或编译

**选项A：直接使用（如果已有可执行文件）**
```bash
# Windows
cd proxy
ssheasy.exe -port 8080

# Linux/Mac
cd proxy
./ssheasy -port 8080
```

**选项B：从源码编译**
```bash
# Windows
build.bat

# Linux/Mac
chmod +x build.sh
./build.sh
```

### 2. 启动服务

```bash
cd proxy
# Windows
ssheasy.exe -port 8080

# Linux/Mac
./ssheasy -port 8080
```

你会看到：
```
2025/10/18 12:30:00 server starts on: :8080
```

### 3. 打开浏览器

访问：`http://localhost:8080/cl/`

## 📝 连接SSH服务器

1. **填写连接信息**：
   - 用户名：root（默认）
   - 主机地址：你的SSH服务器IP或域名
   - 端口：22（默认）
   - 密码：你的SSH密码

2. **点击"连接"按钮**

3. **确认服务器指纹**（首次连接时）

4. **开始使用**！

## 🔧 常用命令行参数

```bash
# 指定端口
ssheasy -port 8080

# 指定监听地址
ssheasy -pub :9000

# 设置日志文件
ssheasy -port 8080 -al /var/log/ssh-connections.log

# 查看所有参数
ssheasy -h
```

## 💡 实用技巧

### URL自动连接

创建书签或分享链接，自动填充连接信息：

```
http://localhost:8080/cl/connect?host=192.168.1.100&user=root&password=mypassword
```

### 文件浏览器

连接成功后，点击"显示文件浏览器"按钮，即可浏览和管理远程文件。

### WebAuthn密钥认证

1. 点击"创建 Webauthn 密钥"
2. 输入密钥名称
3. 复制生成的公钥到服务器 `~/.ssh/authorized_keys`
4. 下次连接时选择该密钥

## ⚠️ 注意事项

- 首次连接会提示确认服务器指纹，这是正常的安全措施
- 所有凭据仅在浏览器和SSH服务器之间传输，不经过代理服务器
- 建议在生产环境中使用HTTPS和反向代理
- 可执行文件已包含所有资源，无需额外文件

## 🐛 常见问题

**Q: 编译失败怎么办？**
A: 确保已安装 Go 1.21 或更高版本，运行 `go version` 检查。

**Q: 连接失败？**
A: 检查网络连接、防火墙设置和SSH服务器配置。

**Q: 如何停止服务？**
A: 在终端按 `Ctrl+C`。

**Q: 如何在后台运行？**
A:
```bash
# Linux/Mac
nohup ./ssheasy -port 8080 > ssheasy.log 2>&1 &

# Windows (使用 PowerShell)
Start-Process -NoNewWindow -FilePath ".\ssheasy.exe" -ArgumentList "-port","8080"
```

## 📚 更多信息

查看完整文档：[README_CN.md](README_CN.md)

---

🎉 享受使用 SSHEasy！
