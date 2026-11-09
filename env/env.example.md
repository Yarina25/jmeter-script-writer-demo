# 环境配置示例（env.example.md）

复制本文件为 `env.local.md`（或按团队约定），替换为真实值。**不要把真实密钥提交进仓库或发进对话**。

## 环境分层

| 环境 | 域名占位 | 用途 |
|---|---|---|
| test（测试） | https://api-test.example.com | 默认目标，脚本用这个 |
| staging（预发） | https://api-staging.example.com | 发布前回归 |
| prod（生产） | https://api.example.com | 禁止直接压测，需评审 |

## 运行环境变量（Windows PowerShell）

```powershell
# 设置 JMeter 安装目录（当前会话有效）
$env:JMETER_HOME = "D:\apache-jmeter-5.6.3"

# 永久设置（用户级）
[Environment]::SetEnvironmentVariable("JMETER_HOME", "D:\apache-jmeter-5.6.3", "User")
```

## 脚本内需替换的占位符

| 文件 | 占位符 | 替换为 |
|---|---|---|
| perf/jmx/*.jmx | api.example.com | 目标环境真实域名 |
| perf/jmx/*.jmx | /api/v1/auth/login、/api/v1/user/me | 真实接口路径 |
| perf/jmx/*.jmx | $.data.access_token | 登录响应中 token 的真实 JSONPath |
| data/login_users.csv | alice/Passw0rd! 等 | 测试环境独立账号（脱敏） |
| perf/jmx/login_api_perf_baseline.jmx | 20 用户/30s/300s | 按压测分级调整 |
