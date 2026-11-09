# JMeter 脚本生成示例工程

> 一套输入骨架，产出「功能验证」与「性能基线」两类 JMeter 脚本；配套一键非 GUI 执行，直接出 `.jtl` 原始数据与 HTML 报告。

本目录是 `jmeter-script-writer` 技能的可执行示例工程，用来演示**同一份接口信息，如何切换出两种用途的压测脚本**，以及如何用一条命令完成非 GUI 执行与报告产出。

---

## 一、这个工程解决什么

手写 `.jmx` 有三个反复出现的痛点：XML 结构容易写错、断言只做一半（只看 HTTP 200 不看业务码）、正式压测时忘了关调试监听器导致压测机自己成了瓶颈。

这个工程把这三件事固化成模板：

| 角色 | 提供什么 |
|---|---|
| `login_api_function.jmx` | **功能验证脚本**：1 用户 1 循环，开调试监听器，用于确认链路通、断言对 |
| `login_api_perf_baseline.jmx` | **性能基线脚本**：20 用户 / 爬坡 30s / 持续 5 分钟，全量关闭 GUI 监听器，带 1s 思考时间 |
| `run_jmeter.ps1` | **一键执行**：前置校验 → 自动时间戳命名 → 非 GUI 跑 → 产出 jtl + HTML → 透传退出码 |
| `env/env.example.md` | **环境分层**：test / staging / prod 三套域名与占位符替换清单 |

两者的差异只有线程组参数与监听器开关，业务链路完全一致——所以「功能验证通过」之后，性能脚本不需要重写一遍。

---

## 二、目录结构

```
jmeter-script-writer-demo/
├── perf/jmx/
│   ├── login_api_function.jmx        # 功能验证：登录 → 提取 token → 查询，1 用户 1 循环
│   └── login_api_perf_baseline.jmx   # 性能基线：20 用户 / 爬坡 30s / 持续 300s
├── data/
│   └── login_users.csv               # 参数化账号，表头即变量名
├── env/
│   └── env.example.md                # 环境分层与占位符清单（含 prod 禁止压测约定）
├── reports/
│   ├── jtl/                          # 非 GUI 运行生成的原始采样数据
│   └── html/                         # 非 GUI 运行生成的 HTML 报告
├── run_jmeter.ps1                    # 一键非 GUI 运行（Windows PowerShell）
├── 使用说明.md                        # 快速上手版说明
└── README.md
```

---

## 三、脚本里固化了哪些设计

| 设计点 | 具体做法 | 为什么重要 |
|---|---|---|
| **双维度断言** | HTTP 状态码 `200` + 业务 `code=0` 两条 `ResponseAssertion` | 接口返回 200 但业务失败是最常见的漏网之鱼 |
| **token 关联带兜底** | `JSONPostProcessor` 取 `$.data.access_token`，默认值 `TOKEN_NOT_FOUND` | 提取失败时不会静默传空，能一眼看出关联断了 |
| **参数化** | `CSVDataSet` 读 `data/login_users.csv`，表头 `username,password` 即变量名 | 避免所有虚拟用户共用同一账号导致串数据 |
| **鉴权头** | 查询接口独立 `HeaderManager`，`Bearer ${access_token}` | 登录态与业务请求分离，便于替换鉴权方式 |
| **思考时间** | 基线脚本内 `ConstantTimer` 1s | 贴近真实用户节奏，避免把接口压到不真实的极限 |
| **监听器默认关闭** | 功能脚本的「查看结果树」`enabled="false"`，正式跑前保持禁用 | 监听器会吃压测机内存与 CPU，污染测试结论 |
| **无 GUI 采样** | 一律 `-n` 非 GUI + `-e -o` 生成 HTML 报告 | 图形界面本身消耗资源，压测结论不可信 |

---

## 四、前置条件

1. **JMeter 5.x**（建议 5.6.3）：https://jmeter.apache.org/download_jmeter.cgi
2. **设置 `JMETER_HOME`** 指向解压目录：

```powershell
$env:JMETER_HOME = "D:\apache-jmeter-5.6.3"          # 当前会话有效
[Environment]::SetEnvironmentVariable("JMETER_HOME", "D:\apache-jmeter-5.6.3", "User")   # 永久
```

3. **替换占位符**：按 [`env/env.example.md`](./env/env.example.md) 把示例域名、接口路径、token JSONPath、CSV 账号换成测试环境的真实值（**用脱敏测试账号，不要提交真实密钥**）。

---

## 五、快速开始

### 第 1 步：功能验证（GUI 调试）

```text
1. 启动 JMeter（jmeter.bat 或命令行 jmeter）
2. 打开 perf/jmx/login_api_function.jmx
3. 勾选「查看结果树(调试用)」→ 运行
4. 确认两个断言都绿：状态码 200、业务 code=0
5. 验证通过后取消勾选，保持禁用
```

### 第 2 步：非 GUI 执行 + HTML 报告

```powershell
cd D:\projects\jmeter-script-writer\jmeter-script-writer-demo
.\run_jmeter.ps1 -Script perf\jmx\login_api_perf_baseline.jmx
```

等价的原生命令：

```powershell
& "$env:JMETER_HOME\bin\jmeter.bat" -n -t perf\jmx\login_api_perf_baseline.jmx `
  -l reports\jtl\login_baseline.jtl -e -o reports\html\login_baseline
```

`run_jmeter.ps1` 做的事：

1. 校验 `JMETER_HOME`、`jmeter.bat`、目标脚本三者是否存在，缺一个立刻报错退出
2. 未指定 `-JtlName` 时自动命名 `<脚本名>_<yyyyMMdd_HHmmss>`，避免覆盖历史结果
3. 调 `-n -t -l -e -o` 跑非 GUI，同时产出 jtl 与 HTML
4. 非零退出码原样透传，可直接被 CI 判定

### 第 3 步：看结果

| 产物 | 路径 |
|---|---|
| 原始采样数据 | `reports/jtl/<名称>.jtl` |
| HTML 报告 | `reports/html/<名称>/index.html`（浏览器直接打开） |

---

## 六、验收指标（默认阈值）

| 指标 | 阈值 | 说明 |
|---|---|---|
| 错误率 | < 1% | 含断言失败，不只是连接失败 |
| P95 响应时间 | < 800ms | 关注长尾，不看平均值 |
| 吞吐 TPS | 结合资源观察 | 配合压测机 / 被测机 CPU、内存抖动一起判读 |

---

## 七、已知边界（首次使用务必先读）

1. 两份 `.jmx` 已通过 XML 结构校验，**首次运行请先在测试环境用低并发冒烟**，确认断言与关联都正确，再逐级加压。
2. **CSV 相对路径以启动目录为基准**：`data/login_users.csv` 是相对路径，请从本目录（demo 根）执行脚本，否则会读不到数据。
3. **账号为脱敏示例**：`data/login_users.csv` 里的 `Passw0rd!` 仅为占位，必须替换为测试环境独立账号。
4. **prod 环境禁止直接压测**：`env/env.example.md` 已标明，生产压测需走评审流程。

---

## 八、常见问题

| 现象 | 原因 | 解决 |
|---|---|---|
| `未设置 JMETER_HOME` | 环境变量缺失 | 设 `$env:JMETER_HOME`，或传 `-JmeterHome` |
| 所有请求返回 401 / 关联取不到 token | JSONPath 与实际响应结构不符 | 按 `env.example.md` 修正 `$.data.access_token` 路径；看提取默认值是否变成 `TOKEN_NOT_FOUND` |
| 断言全绿但业务其实是失败的 | 只做了状态码断言 | 补业务 `code=0` 断言，这是本模板的默认设计 |
| 压测机 CPU 打满、被测服务却很闲 | 忘了关监听器，或用了 GUI 模式 | 确认 `enabled="false"`，一律走 `-n` 非 GUI |
| CSV 读不到账号 | 启动目录不对 | 从 demo 根目录执行，或把 CSV 路径改为绝对路径 |

---

## 九、与技能的关系

本工程是 `jmeter-script-writer` 技能的**可执行示例**。技能提供输入模板，把真实接口信息填进去，即可按同一骨架生成新的功能脚本或性能脚本，不必理解 XML 结构。

---

## 十、License

未附带许可证文件，如需开源发布请自行补充。
