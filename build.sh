#!/bin/bash
# SSHEasy 多平台交叉编译脚本 - Linux/Mac

echo "================================"
echo "SSHEasy 多平台交叉编译脚本"
echo "================================"
echo ""

# 显示帮助信息
function show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -p, --platform      指定编译平台 (linux/windows/darwin/all)"
    echo "                      不指定则只编译当前平台"
    echo ""
    echo "示例:"
    echo "  $0                  # 编译当前平台"
    echo "  $0 -p linux         # 编译 Linux 平台"
    echo "  $0 -p windows       # 编译 Windows 平台"
    echo "  $0 -p darwin        # 编译 macOS 平台"
    echo "  $0 -p all           # 编译所有平台"
    echo ""
}

# 解析命令行参数
PLATFORM=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 步骤1：编译 WebAssembly 客户端
echo "[1/4] 编译 WebAssembly 客户端..."
cd web
GOOS=js GOARCH=wasm go build -o html/main.wasm
if [ $? -ne 0 ]; then
    echo "❌ 错误：WebAssembly 编译失败"
    exit 1
fi
echo "✅ WebAssembly 编译成功！"
cd ..

# 步骤2:复制 wasm_exec.js
echo ""
echo "[2/4] 复制 wasm_exec.js..."
GOROOT_PATH=$(go env GOROOT)

# 尝试多个可能的路径
WASM_EXEC_FOUND=0
if [ -f "$GOROOT_PATH/misc/wasm/wasm_exec.js" ]; then
    cp "$GOROOT_PATH/misc/wasm/wasm_exec.js" "web/html/wasm_exec.js"
    WASM_EXEC_FOUND=1
elif [ -f "$GOROOT_PATH/lib/wasm/wasm_exec.js" ]; then
    cp "$GOROOT_PATH/lib/wasm/wasm_exec.js" "web/html/wasm_exec.js"
    WASM_EXEC_FOUND=1
fi

if [ $WASM_EXEC_FOUND -eq 1 ]; then
    echo "✅ wasm_exec.js 复制完成"
else
    echo "❌ 错误：找不到 wasm_exec.js 文件"
    echo "   已尝试路径:"
    echo "     - $GOROOT_PATH/misc/wasm/wasm_exec.js"
    echo "     - $GOROOT_PATH/lib/wasm/wasm_exec.js"
    exit 1
fi

# 步骤3：复制 HTML 资源到 proxy 目录
echo ""
echo "[3/4] 准备资源文件..."
cp -r web/html proxy/
echo "✅ 资源文件准备完成"

# 步骤4：交叉编译服务端
echo ""
echo "[4/4] 编译服务端程序..."
cd proxy
go mod tidy

# 清除并创建输出目录
OUTPUT_DIR="../build"
if [ -d "$OUTPUT_DIR" ]; then
    echo "🗑️  清除旧的构建文件..."
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"
echo "✅ 构建目录已准备"

# 编译函数
function build_platform() {
    local GOOS=$1
    local GOARCH=$2
    local OUTPUT_NAME=$3

    echo ""
    echo "📦 正在编译 ${GOOS}/${GOARCH}..."

    env GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w" -o "${OUTPUT_DIR}/${OUTPUT_NAME}"

    if [ $? -eq 0 ]; then
        local SIZE=$(du -h "${OUTPUT_DIR}/${OUTPUT_NAME}" | cut -f1)
        echo "✅ ${GOOS}/${GOARCH} 编译成功! 文件大小: ${SIZE}"
    else
        echo "❌ ${GOOS}/${GOARCH} 编译失败!"
        return 1
    fi
}

# 根据参数决定编译哪些平台
# 如果未指定平台，默认编译所有平台
if [ -z "$PLATFORM" ]; then
    PLATFORM="all"
    echo "未指定平台，默认编译所有平台..."
fi

case "$PLATFORM" in
    "linux")
        echo "编译 Linux 平台..."
        build_platform "linux" "amd64" "ssheasy-linux-amd64"
        build_platform "linux" "arm64" "ssheasy-linux-arm64"
        ;;
    "windows")
        echo "编译 Windows 平台..."
        build_platform "windows" "amd64" "ssheasy-windows-amd64.exe"
        build_platform "windows" "arm64" "ssheasy-windows-arm64.exe"
        ;;
    "darwin")
        echo "编译 macOS 平台..."
        build_platform "darwin" "amd64" "ssheasy-darwin-amd64"
        build_platform "darwin" "arm64" "ssheasy-darwin-arm64"
        ;;
    "all")
        echo "编译所有平台..."
        build_platform "linux" "amd64" "ssheasy-linux-amd64"
        build_platform "linux" "arm64" "ssheasy-linux-arm64"
        build_platform "windows" "amd64" "ssheasy-windows-amd64.exe"
        build_platform "windows" "arm64" "ssheasy-windows-arm64.exe"
        build_platform "darwin" "amd64" "ssheasy-darwin-amd64"
        build_platform "darwin" "arm64" "ssheasy-darwin-arm64"
        ;;
    *)
        echo "❌ 错误：不支持的平台 '$PLATFORM'"
        echo "支持的平台: linux, windows, darwin, all"
        exit 1
        ;;
esac

cd ..

echo ""
echo "================================"
echo "✅ 编译完成！"
echo "================================"
echo ""
echo "📁 编译产物目录: build/"
echo "📦 已编译所有平台和架构"
echo ""
echo "🚀 运行方式 (以 Linux 为例):"
echo "  cd build"
echo "  ./ssheasy-linux-amd64 -port 8080"
echo ""
echo "🚀 运行方式 (以 Windows 为例):"
echo "  cd build"
echo "  ssheasy-windows-amd64.exe -port 8080"
echo ""
echo "🌐 然后在浏览器中打开: http://localhost:8080/cl/"

echo ""
echo "⚙️  命令行参数说明:"
echo "  -port 端口号         设置监听端口 (默认: 5555)"
echo "  -pub 地址           设置公共监听地址"
echo "  -priv 地址          设置管理监听地址 (默认: :6666)"
echo "  -adm-key 密钥       设置管理 API 密钥"
echo "  -al 日志文件        设置审计日志文件路径"
echo "  -debug              启用调试模式，显示详细日志"
echo ""
