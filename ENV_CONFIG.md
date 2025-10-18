# SSHEasy 配置说明

## 命令行参数配置

您可以通过以下命令行参数来配置SSHEasy：

### 基本配置
- `-port`: 监听端口（默认：`5555`）
- `-pub`: 公共监听地址（默认：`:5555`）
- `-al`: 审计日志文件路径（默认：`connections.log`）
- `-debug`: 启用调试模式，显示详细日志（默认：`false`）

### 安全配置
- `-priv`: 管理监听地址（默认：`:6666`）
- `-adm-key`: 管理 API 密钥

## 使用方法

### Windows
```cmd
# 生产环境（无调试日志）
ssheasy.exe -port 8080

# 开发环境（启用调试日志）
ssheasy.exe -port 8080 -debug
```

### Linux/Mac
```bash
# 生产环境（无调试日志）
./ssheasy -port 8080

# 开发环境（启用调试日志）
./ssheasy -port 8080 -debug
```

### 生产环境建议
```bash
# 关闭调试日志，使用默认端口
./ssheasy

# 自定义端口和日志文件
./ssheasy -port 5555 -al /var/log/ssheasy/connections.log
```

## 环境变量（可选）

虽然推荐使用命令行参数，但您仍可以通过环境变量设置默认值：

- `DEBUG`: 调试模式（默认：`false`）
- `PORT`: 监听端口（默认：`5555`）
- `PUBLIC_ADDR`: 公共监听地址（默认：`:5555`）
- `AUDIT_LOG_FILE`: 审计日志文件（默认：`connections.log`）

## 构建说明

### 编译所有平台
```bash
# Windows
build.bat -p all

# Linux/Mac
./build.sh -p all
```

### 编译产物
所有可执行文件将输出到 `build/` 目录：
- `ssheasy-linux-amd64` - Linux x86_64
- `ssheasy-linux-arm64` - Linux ARM64
- `ssheasy-windows-amd64.exe` - Windows x86_64
- `ssheasy-windows-arm64.exe` - Windows ARM64
- `ssheasy-darwin-amd64` - macOS x86_64
- `ssheasy-darwin-arm64` - macOS ARM64
