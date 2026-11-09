# run_jmeter.ps1 - JMeter 非 GUI 运行脚本（Windows）
# 用法:
#   .\run_jmeter.ps1 -Script perf\jmx\login_api_perf_baseline.jmx
#   .\run_jmeter.ps1 -Script perf\jmx\login_api_function.jmx -JtlName login_debug
# 依赖:
#   - 已安装 JMeter 并设置环境变量 JMETER_HOME（如 D:\apache-jmeter-5.6.3）
#   - 或在调用时用 -JmeterHome 指定
# 产出:
#   - reports/jtl/<名称>.jtl   原始采样数据
#   - reports/html/<名称>/     HTML 报告（index.html 可直接打开）

param(
    [Parameter(Mandatory = $true)]
    [string]$Script,

    [string]$JmeterHome = $env:JMETER_HOME,

    [string]$JtlDir = "reports\jtl",

    [string]$HtmlDir = "reports\html",

    [string]$JtlName = ""
)

$ErrorActionPreference = "Stop"

# 1. 前置检查
if (-not $JmeterHome) {
    Write-Error "未设置 JMETER_HOME。请先执行: `$env:JMETER_HOME = 'D:\apache-jmeter-5.6.3' 或使用 -JmeterHome 参数。"
    exit 1
}
$jmeterBat = Join-Path $JmeterHome "bin\jmeter.bat"
if (-not (Test-Path -LiteralPath $jmeterBat)) {
    Write-Error "未找到 jmeter.bat: $jmeterBat"
    exit 1
}
$scriptFull = (Resolve-Path -LiteralPath $Script).Path
if (-not (Test-Path -LiteralPath $scriptFull)) {
    Write-Error "脚本不存在: $Script"
    exit 1
}

# 2. 目录与命名
if (-not $JtlName) {
    $JtlName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFull) + "_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}
New-Item -ItemType Directory -Force -Path $JtlDir | Out-Null
New-Item -ItemType Directory -Force -Path $HtmlDir | Out-Null
$jtlFile = Join-Path $JtlDir ($JtlName + ".jtl")
$outHtmlDir = Join-Path $HtmlDir $JtlName

# 3. 非 GUI 执行（-n 非GUI / -t 脚本 / -l jtl / -e -o HTML 报告）
Write-Host "==> 开始执行: $scriptFull"
Write-Host "    结果数据: $jtlFile"
& $jmeterBat -n -t $scriptFull -l $jtlFile -e -o $outHtmlDir
if ($LASTEXITCODE -ne 0) {
    Write-Error "JMeter 执行失败，退出码: $LASTEXITCODE。请检查脚本与目标环境。"
    exit $LASTEXITCODE
}

# 4. 结果提示
Write-Host "==> 执行完成"
Write-Host "    原始数据: $jtlFile"
Write-Host "    HTML 报告: $outHtmlDir\index.html"
Write-Host "    打开报告: Start-Process `"$outHtmlDir\index.html`""
exit 0
