# SSHEasy PowerShell Build Script
# PowerShell version of build script

Write-Host "================================" -ForegroundColor Cyan
Write-Host "SSHEasy Multi-platform Cross-compilation Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Parse command line arguments
$platform = "all"
if ($args.Count -gt 0) {
    $platform = $args[0].ToLower()
}

Write-Host "Building platform: $platform" -ForegroundColor Green
Write-Host ""

# Step 1: Compile WebAssembly client
Write-Host "[1/4] Compiling WebAssembly client..." -ForegroundColor Yellow
Set-Location web1
$env:GOOS = "js"
$env:GOARCH = "wasm"
go build -o html/main.wasm
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Error: WebAssembly compilation failed" -ForegroundColor Red
    Set-Location ..
    Read-Host "Press Enter to continue"
    exit 1
}
Write-Host "[√] WebAssembly compilation successful!" -ForegroundColor Green

# Reset environment variables
$env:GOOS = ""
$env:GOARCH = ""
Set-Location ..

# Step 2: Copy HTML resources to proxy directory
Write-Host ""
Write-Host "[2/4] Preparing resource files..." -ForegroundColor Yellow
if (Test-Path "proxy\html") {
    Remove-Item "proxy\html" -Recurse -Force
}
Copy-Item "web1\html" "proxy\html" -Recurse -Force
Write-Host "[√] Resource files preparation completed" -ForegroundColor Green

# Step 3: Copy wasm_exec.js
Write-Host ""
Write-Host "[3/4] Copying wasm_exec.js..." -ForegroundColor Yellow
$goroot = go env GOROOT
$wasmExecFound = $false

$paths = @(
    "$goroot\misc\wasm\wasm_exec.js",
    "$goroot\lib\wasm\wasm_exec.js"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Copy-Item $path "web1\html\wasm_exec.js" -Force
        $wasmExecFound = $true
        break
    }
}

if ($wasmExecFound) {
    Write-Host "[√] wasm_exec.js copy completed" -ForegroundColor Green
} else {
    Write-Host "[X] Error: Cannot find wasm_exec.js file" -ForegroundColor Red
    Write-Host "    Tried paths:" -ForegroundColor Yellow
    foreach ($path in $paths) {
        Write-Host "      - $path" -ForegroundColor Yellow
    }
    Read-Host "Press Enter to continue"
    exit 1
}

# Step 4: Cross-compile server
Write-Host ""
Write-Host "[4/4] Compiling server program..." -ForegroundColor Yellow
Set-Location proxy
go mod tidy

# Clear and create output directory
$outputDir = "..\build"
if (Test-Path $outputDir) {
    Write-Host "[*] Clearing old build files..." -ForegroundColor Yellow
    Remove-Item $outputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
Write-Host "[√] Build directory prepared" -ForegroundColor Green

# Build function
function Build-Platform {
    param($goos, $goarch, $output)
    
    Write-Host ""
    Write-Host "[*] Compiling $goos/$goarch..." -ForegroundColor Yellow
    
    $env:GOOS = $goos
    $env:GOARCH = $goarch
    go build -ldflags="-s -w" -o "$outputDir\$output"
    
    if ($LASTEXITCODE -eq 0) {
        $file = Get-Item "$outputDir\$output"
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "[√] $goos/$goarch compilation successful! File size: $sizeMB MB" -ForegroundColor Green
    } else {
        Write-Host "[X] $goos/$goarch compilation failed!" -ForegroundColor Red
    }
}

# Build based on platform
switch ($platform) {
    "linux" {
        Write-Host ""
        Write-Host "Compiling Linux platform..." -ForegroundColor Cyan
        Build-Platform "linux" "amd64" "ssheasy-linux-amd64"
        Build-Platform "linux" "arm64" "ssheasy-linux-arm64"
    }
    "windows" {
        Write-Host ""
        Write-Host "Compiling Windows platform..." -ForegroundColor Cyan
        Build-Platform "windows" "amd64" "ssheasy-windows-amd64.exe"
        Build-Platform "windows" "arm64" "ssheasy-windows-arm64.exe"
    }
    "darwin" {
        Write-Host ""
        Write-Host "Compiling macOS platform..." -ForegroundColor Cyan
        Build-Platform "darwin" "amd64" "ssheasy-darwin-amd64"
        Build-Platform "darwin" "arm64" "ssheasy-darwin-arm64"
    }
    "all" {
        Write-Host ""
        Write-Host "Compiling all platforms..." -ForegroundColor Cyan
        Build-Platform "linux" "amd64" "ssheasy-linux-amd64"
        Build-Platform "linux" "arm64" "ssheasy-linux-arm64"
        Build-Platform "windows" "amd64" "ssheasy-windows-amd64.exe"
        Build-Platform "windows" "arm64" "ssheasy-windows-arm64.exe"
        Build-Platform "darwin" "amd64" "ssheasy-darwin-amd64"
        Build-Platform "darwin" "arm64" "ssheasy-darwin-arm64"
    }
    default {
        Write-Host "[X] Error: Unsupported platform '$platform'" -ForegroundColor Red
        Write-Host "    Supported platforms: linux, windows, darwin, all" -ForegroundColor Yellow
        Set-Location ..
        Read-Host "Press Enter to continue"
        exit 1
    }
}

Set-Location ..

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "[√] Compilation completed!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Build output directory: build\" -ForegroundColor Cyan
Write-Host "📦 All platforms and architectures compiled" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Run instructions (Windows example):" -ForegroundColor Yellow
Write-Host "  cd build" -ForegroundColor White
Write-Host "  ssheasy-windows-amd64.exe -port 8080" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Run instructions (Linux example):" -ForegroundColor Yellow
Write-Host "  cd build" -ForegroundColor White
Write-Host "  ./ssheasy-linux-amd64 -port 8080" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Then open in browser: http://localhost:8080/cl/" -ForegroundColor Cyan

Write-Host ""
Write-Host "⚙️  Command line parameters:" -ForegroundColor Yellow
Write-Host "  -port port_number     Set listening port (default: 5555)" -ForegroundColor White
Write-Host "  -pub address          Set public listening address" -ForegroundColor White
Write-Host "  -priv address          Set management listening address (default: :6666)" -ForegroundColor White
Write-Host "  -adm-key key           Set management API key" -ForegroundColor White
Write-Host "  -al log_file           Set audit log file path" -ForegroundColor White
Write-Host "  -debug                 Enable debug mode, show detailed logs" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue"
