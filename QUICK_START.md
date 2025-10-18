# SSHEasy 快速使用指南

## 🚀 快速开始

### 1. 编译项目
```bash
# Windows
build.bat -p all

# Linux/Mac
./build.sh -p all
```

### 2. 运行服务
```bash
# 生产环境（无调试日志）
./ssheasy -port 8080

# 开发环境（启用调试日志）
./ssheasy -port 8080 -debug
```

### 3. 访问界面
打开浏览器访问：`http://localhost:8080/cl/`

## 📋 命令行参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `-port` | 监听端口 | 5555 | `-port 8080` |
| `-pub` | 监听地址 | :5555 | `-pub :8080` |
| `-al` | 日志文件 | connections.log | `-al /var/log/ssheasy.log` |
| `-debug` | 调试模式 | false | `-debug` |

## 🎯 使用场景

### 开发调试
```bash
./ssheasy -port 8080 -debug
```
- 显示详细连接日志
- 便于问题排查

### 生产部署
```bash
./ssheasy -port 5555 -al /var/log/ssheasy.log
```
- 关闭调试日志
- 记录审计日志

### 快速测试
```bash
./ssheasy
```
- 使用默认配置
- 端口5555

## 🔧 功能特性

- ✅ **完全本地化**：无外部依赖
- ✅ **多平台支持**：Linux/Windows/macOS
- ✅ **美观界面**：现代化设计
- ✅ **状态反馈**：连接状态弹窗
- ✅ **安全日志**：审计日志记录
- ✅ **调试模式**：可控制日志输出

## 📁 文件说明

- `build/` - 编译产物目录
- `proxy/ssheasy.exe` - Windows可执行文件
- `proxy/connections.log` - 连接日志文件
- `web/html/` - Web界面文件

## 🆘 常见问题

### Q: 如何启用调试模式？
A: 添加 `-debug` 参数即可

### Q: 如何自定义端口？
A: 使用 `-port` 参数，如 `-port 8080`

### Q: 如何查看连接日志？
A: 查看 `connections.log` 文件

### Q: 支持哪些平台？
A: Linux/Windows/macOS，支持amd64和arm64架构

## 📞 技术支持

如有问题，请查看：
- `ENV_CONFIG.md` - 详细配置说明
- `IMPROVEMENTS_SUMMARY.md` - 功能改进总结
- GitHub Issues - 问题反馈
