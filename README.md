# MatrixHunter

> 面向授权安全测试的 Windows 桌面漏洞验证工具：确定性证据 + 本地 AI 助手 + 动态 Payload 模拟攻击。

**当前版本：1.0.4** ｜ **平台：Windows 10/11 x64** ｜ **界面：WebView2 + Matrix 主题**

> 📦 **安装包说明：** 下载 `dist/` 下的分卷后，运行 `dist/join-installer.ps1` 会合并成完整的 `MatrixHunter-1.0.4.msi`，并自动校验 SHA256。

> ⚠️ **仅限授权测试。** 请只对你拥有或已获得明确书面授权的目标使用本工具。使用者需自行承担因未授权测试产生的一切法律责任。

---

## 目录

- 项目简介
- 核心特性
- 漏洞收录口径
- 工作原理
- 系统要求
- 安装与卸载
- 快速开始
- 功能详解
  - 指挥中心
  - 实时扫描
  - 深度挖掘
  - 漏洞证据
  - 审计报告
  - 系统设置
  - 告警
  - AI 动态 Payload
- MCP 工具
- 数据与文件位置
- 常见问题
- 更新日志
- 安全与合规
- 反馈

---

## 项目简介

MatrixHunter 是一款运行在 Windows 上的桌面安全测试工具，使用 Go 编写，界面基于 WebView2，采用 Matrix 风格的中文 UI。

它把 **扫描、验证、取证、报告** 放在同一个本地应用里。和只给出“疑似漏洞”的扫描器不同，MatrixHunter 只有在拿到可复现的真实响应证据时，才会把问题列为 **已验证漏洞**。AI 助手负责调度扫描工具、解释结果、根据目标上下文生成验证型 Payload，但不会替代确定性引擎做最终裁决，也不会编造漏洞。

适合以下场景：

- 对已授权 Web 业务做 SQL 注入、文件包含、SSTI、命令注入、敏感文件/备份泄露等验证。
- 对已授权主机做端口、服务与未授权访问排查。
- 对本地源代码做硬编码凭据、危险调用与敏感信息排查。
- 让 AI 基于真实扫描面动态生成 Payload，做二次模拟攻击复核。

---

## 核心特性

| 能力 | 说明 |
| --- | --- |
| 确定性验证 | 只有真实响应、可复现证据才进入“已验证漏洞”；AI 不直接判定漏洞 |
| 三种扫描模式 | Web 应用、主机/端口、本地源代码 |
| 独立深度挖掘 | Deep 模式会进入独立的深度挖掘阶段，而不是简单调大参数 |
| AI 指挥中心 | 内置 OpenCode 服务，流式对话、工具调用、执行过程展示、可中止 |
| 免费模型 | 自动发现并选择支持工具调用的免费模型，可在界面切换 |
| AI 动态 Payload | AI 按参数生成 sqli/xss/lfi/ssti/cmdi 验证载荷，引擎独立验证并保存到共享库 |
| 扫描同步 | AI 保存的 Payload 会按主机自动复用到后续 Web 扫描 |
| 严格收录口径 | 按补天 SRC 的“数据危害”标准过滤加固项、端口开放、版本泄露等低价值结果 |
| 实时反馈 | 扫描日志、进度、漏洞、线索、统计实时推送到界面 |
| 原生桌面体验 | 界面内嵌在 WebView2 中，不打开外部浏览器，也不弹出控制台窗口 |
| 强提醒 | 每个严重/高危/中危已验证漏洞播放 3 次对应等级音频，持续红框与弹窗，确认后才停止 |
| 审计报告 | 自动生成 Markdown + JSON 报告，包含证据、影响、修复建议与过滤记录 |
| 本地优先 | 配置、扫描结果、报告、Payload 库全部保存在本机；无需单独安装 OpenCode |
| 会话授权 | 授权只在当前会话有效，关闭应用后自动失效，重启需重新确认 |

---

## 漏洞收录口径

MatrixHunter 使用严格的“数据危害”口径，把结果分为三类：

### 已验证漏洞（Verified Findings）

必须能证明 **敏感数据泄露** 或 **可直接读取/控制业务数据**。例如：

- SQL 注入，并能从真实响应中复现数据库错误或时间盲注差异。
- 路径穿越 / LFI，并能读取到真实系统文件内容。
- SSTI / 命令注入 / RCE，并能用实际回显或计算结果证明执行。
- 可下载的源码备份、数据库导出、包含真实凭据的配置文件。
- 未授权数据库 / Redis / Memcached 等服务，并能读取真实数据或执行受控操作。
- IDOR / 未授权接口，且响应中包含足够数量的真实个人信息或敏感业务数据。
- 数据库连接串、私钥等可直接用于访问数据的硬编码凭据。

### 未验证线索（Unverified Leads）

有迹象但还不足以证明数据危害，需要人工确认。例如：

- XSS 反射 / DOM 执行证据（严格口径下默认作为线索，除非能进一步证明数据泄露链）。
- 仅匹配到密钥格式、但未验证有效性的硬编码凭据。
- 响应中出现少量敏感字段，但数量/类型不足以证明批量泄露。
- 可疑接口、异常参数行为、需要登录态才能继续验证的入口。

> 线索不是漏洞。界面和 AI 都会明确标注“未验证 / 需人工确认”。

### 已过滤（Filtered Items）

只影响加固或资产暴露、未证明数据危害的问题会被过滤，并保留在审计记录中：

- TLS 协议/证书问题、HSTS、Cookie 属性、安全响应头。
- CORS 配置、开放重定向、CRLF、TRACE。
- 端口开放、服务版本号、目录列表（未列出敏感文件时）。
- 无敏感内容的配置/信息暴露。

`filtered_items` 仅用于审计透明，不应作为漏洞汇报。

---

## 工作原理

```text
授权确认（仅当前会话）
        │
        ▼
目标可达性检查 ──► 基础检查 / 爬虫 / 参数发现
        │
        ├──► Standard / Deep：内置确定性验证（SQLi、LFI、SSTI、XSS、CMDI…）
        │
        ├──► Deep：独立深度挖掘（JS/API、备份/数据库导出、敏感接口、IDOR/PII）
        │
        ├──► AI 动态 Payload（可选）：按 attack_surface 生成 Payload → vh_attack_probe
        │
        ▼
证据去重 / 分级 / 补天口径过滤
        │
        ├──► 已验证漏洞 ──► 音频告警 + 红框 + 弹窗
        ├──► 未验证线索
        └──► 已过滤记录
        │
        ▼
Markdown / JSON 报告 + 界面展示
```

AI 运行在独立的本地 sidecar 进程中：

- 使用安装目录内的 `opencode-cli.exe`，不需要系统里已安装 OpenCode。
- 随机本地端口 + Basic Auth，配置目录与用户现有 OpenCode 隔离。
- 通过 MCP 只暴露 `vh_*` 工具和只读工具，不能执行任意系统命令。
- 主程序退出时通过 Job Object 清理 sidecar 及其子进程。

---

## 系统要求

- Windows 10 / 11，x64。
- **Microsoft Edge WebView2 Runtime**。Windows 11 和大部分 Windows 10 已自带；若界面空白，请安装 Evergreen WebView2 Runtime。
- 约 250 MB 磁盘空间（MSI 约 104 MB，安装后包含 `opencode-cli.exe`）。
- 扫描 Web/主机目标时需要目标网络可达。
- 使用 AI 对话与动态 Payload 时需要联网访问模型服务；扫描引擎本身在本地运行。
- 不需要安装 Python、Node.js、OpenCode 或额外数据库。

---

## 安装与卸载

### 安装

1. 获取 `MatrixHunter-1.0.4.msi`：
   - **方式一（Gitee 推荐）**：从本仓库 [`dist`](dist/) 目录下载 3 个分卷，运行 [`join-installer.ps1`](dist/join-installer.ps1) 合并。Gitee 对单个仓库文件有 50 MB 限制，因此安装包被拆成 3 个分卷，这不是安装包损坏。
   - **方式二**：从 [GitHub Releases](https://github.com/AhangGameStudio/MatrixHunter/releases) 获取完整 MSI。
2. 双击 MSI，按向导选择安装目录。
3. 安装完成后，桌面和开始菜单会生成 `MatrixHunter` 快捷方式。
4. 启动 `MatrixHunter.exe`。

安装目录中的关键文件：

```text
MatrixHunter.exe
opencode-cli.exe
MatrixHunter.ico   （快捷方式图标，可选）
```

`MatrixHunter.exe` 与 `opencode-cli.exe` 必须放在同一目录，否则 AI 功能无法启动。

### 仓库内安装包（分卷）

Gitee 社区版限制单个仓库文件最大 50 MB，而完整 MSI 约 104 MB，因此仓库中的安装包采用 3 个分卷保存：

```text
dist/MatrixHunter-1.0.4.msi.part001
dist/MatrixHunter-1.0.4.msi.part002
dist/MatrixHunter-1.0.4.msi.part003
dist/join-installer.ps1
dist/SHA256SUMS.txt
```

将 3 个分卷和 `join-installer.ps1` 下载到同一个 `dist` 目录，然后在该目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\join-installer.ps1
```

脚本会合并出 `dist\MatrixHunter-1.0.4.msi`，并自动校验大小和 SHA256：

```text
3959F901C889CD0408B180CFD0CAF2896893FFFD35CA53820E5F6159346FB3D6
```

如果哈希不一致，说明分卷下载不完整或已损坏，请重新下载。完整的 SHA256 列表见 [`dist/SHA256SUMS.txt`](dist/SHA256SUMS.txt)。

> GitHub 单个文件上限为 100 MiB，完整 MSI 同样超过限制，因此 GitHub 仓库也使用分卷；GitHub Releases 可作为完整安装包的备用下载方式。

### 静默安装

```powershell
msiexec /i MatrixHunter-1.0.4.msi INSTALLDIR=D:\MH /qn /norestart
```

`INSTALLDIR` 可替换为你自己的路径；不指定时安装到系统默认程序目录。

### 升级

直接安装更高版本的 MSI 即可，安装程序会自动处理旧版本。若重复安装 **相同版本**，Windows Installer 可能生成多个产品条目；建议升级时使用更高版本号。

### 卸载

通过“Windows 设置 → 应用 → 已安装的应用 → MatrixHunter → 卸载”。

卸载不会自动删除 `%LOCALAPPDATA%\MatrixHunter` 下的扫描记录、报告、日志和 Payload 库。如需彻底清理，请在卸载后手动删除该目录。

> 当前 MSI 未做代码签名，Windows SmartScreen 可能提示“未知发布者”。请确认文件来源并校验哈希后再运行。

---

## 快速开始

1. **启动应用**。首次启动会加载内置 AI 服务与免费模型列表。
2. **确认授权**。在授权弹窗中勾选两项确认，点击确认。授权只在本次会话有效。
3. **选择扫描类型**。进入“实时扫描”，选择 `WEB 应用`、`主机 / 端口` 或 `源代码`。
4. **填写目标**。Web 填 `https://example.com`；主机填 IP 或域名；源码填本地目录。
5. **选择强度**。`Quick` 快速摸底、`Standard` 常规、`Deep` 深度挖掘。
6. **保持 AI Payload 开关开启**（Web 扫描建议开启），点击“开始扫描”。
7. **查看结果**。在“漏洞证据”中查看已验证漏洞和未验证线索，展开证据链。
8. **让 AI 复核**。在“指挥中心”输入目标与要求，AI 会调用扫描/探针工具做动态验证。
9. **处理告警**。出现严重/高危/中危漏洞时，音频会连续播放 3 次并保持红框；勾选“我已确认收到告警”并确认后停止。
10. **查看报告**。在“审计报告”中查看历史记录，或到 `%LOCALAPPDATA%\MatrixHunter\scans` 获取 Markdown/JSON。

### 推荐使用顺序

- **第一次接触目标**：使用 Quick 快速摸底，确认目标可达、技术栈和参数形态。
- **常规测试**：Standard + 开启时间盲注，覆盖主要注入与文件类问题。
- **重点业务/复测**：Deep + AI 动态 Payload，让 AI 针对 `attack_surface` 生成目标相关载荷并复核。

---

## 功能详解

### 指挥中心

“指挥中心”是 AI 对话界面，支持：

- 流式输出、工具调用过程展示、执行状态与中止当前任务。
- 自动加载可用的免费模型，可在“系统设置”中切换模型。
- 让 AI 执行 Web/主机/源码扫描、读取扫描结果、解释证据。
- 让 AI 基于真实 `attack_surface` 动态生成 Payload，并调用 `vh_attack_probe` 做模拟攻击。
- AI 的权限被限制为只读工具与 `vh_*` MCP 工具，不能执行任意 shell 命令。

AI 的定位是“操作员 + 解释器”，不是漏洞裁判：

- 只有工具返回的 `verified_findings` 才能被称为已验证漏洞。
- `unverified_leads` 必须标注为未验证线索。
- 没有证据时，AI 应明确说明“当前没有证据”，不得猜测。

### 实时扫描

#### Web 应用

目标格式：`https://example.com`、`http://192.0.2.10:8080`。

主要能力：

- 爬取页面、链接、表单、查询参数。
- SQL 注入：错误型 + 时间盲注。
- 路径穿越 / LFI：系统文件、PHP 源码过滤链等。
- SSTI、命令注入探针。
- XSS 反射/DOM 解析（严格口径下通常作为线索）。
- 敏感文件、环境变量、配置备份、源码/数据库导出探测。
- 未授权接口、IDOR/PII（Deep）。
- AI 动态 Payload 按参数复核。

#### 主机 / 端口

目标格式：`192.0.2.10`、`example.com:443`。

主要能力：

- 常见端口与 Deep 扩展端口探测。
- 服务识别与版本线索。
- 未授权 Redis、Memcached 等服务检查。
- 数据库/中间件暴露检查。

> 仅“端口开放”或“版本号泄露”会被过滤；只有能证明未授权数据访问或控制能力时才可能成为已验证漏洞。

#### 源代码

目标格式：本地目录或单个文件，例如 `D:\code\project`、`D:\code\app\config.php`。

主要能力：

- 硬编码凭据识别：AWS、GitHub、GitLab、OpenAI、Anthropic、Slack、Stripe、Google、私钥、数据库连接串等。
- 通用高熵密钥线索。
- 危险调用静态分析：命令执行、代码执行、反序列化、模板注入、文件包含、DOM XSS 等。
- 源码片段与密钥脱敏展示。
- 默认只分析常见源码/配置文件，单文件不超过 2 MB，最多 8000 个文件。

> 源码扫描只读本地文件，不执行目标代码；硬编码密钥默认不联网验证有效性，避免把密钥发送到第三方。

#### 扫描强度

| 强度 | 默认/至少规模 | 特点 |
| --- | --- | --- |
| Quick | 最多 15 页 / 300 请求，10 秒超时 | 快速摸底，关闭时间盲注 |
| Standard | 默认 40 页 / 900 请求，15 秒超时 | 常规覆盖，开启时间盲注 |
| Deep | 至少 120 页 / 3000 请求，20 秒超时 | 启用独立深度挖掘、扩展端口与更多接口 |

实际页数、请求数、超时可在“系统设置”中调整；Quick 会在你的设置基础上进一步收紧，Deep 会保证不低于上述规模。

> 扫描不额外施加固定请求频率限制，节奏由并发数、页数、请求数和超时控制。请合理设置并发、避免影响业务，并只在授权目标上使用。

### 深度挖掘

深度挖掘是 Deep 模式下的 **独立阶段**，不是简单地把页数调大。它会：

- 从页面与 JS 中提取 API/接口路径，扩展到同主机可测试面。
- 探测源码/备份压缩包、数据库导出、环境变量备份、配置备份。
- 检查未授权接口是否返回真实业务数据或个人信息。
- 检查 IDOR / 越权读取用户数据。
- 对主机扫描启用扩展端口列表。
- 将新发现的参数合并进后续验证队列。

深度挖掘同样遵守“真实响应证据”原则，不会因为路径存在就判定漏洞。

### 漏洞证据

“漏洞证据”页展示：

- **已验证漏洞**：标题、等级、类别、CWE/OWASP、位置、参数、影响、证据、修复建议。
- **数据暴露**：数据类型、数量、脱敏示例（如手机号、身份证、邮箱、地址等）。
- **未验证线索**：需要人工确认的迹象，明确标注“未验证”。

页面支持在“已验证漏洞 / 待确认线索”之间切换，按严重性筛选，并按标题、路径、参数搜索。被补天口径过滤的加固项/资产信息保留在报告和 JSON 的 `filtered` 字段中，用于审计追溯，不会出现在漏洞列表里。证据中可能包含真实响应片段，请谨慎分享。

### 审计报告

每次扫描自动保存两份文件：

```text
%LOCALAPPDATA%\MatrixHunter\scans\<scan-id>.md
%LOCALAPPDATA%\MatrixHunter\scans\<scan-id>.json
```

- Markdown：适合人工阅读、复制到工单/报告。
- JSON：适合二次处理、归档或接入其他系统。

报告包含摘要、统计、已验证漏洞、证据、线索、过滤记录和错误信息。报告可能包含敏感数据，请按内部安全规范存储和传输。

### 系统设置

| 设置 | 默认值 | 说明 |
| --- | --- | --- |
| 扫描强度 | Standard | Quick / Standard / Deep |
| 超时 | 15 秒 | 单请求超时，范围 3–60 秒 |
| 并发 | 8 | 同时请求数，范围 1–32 |
| 最大页数 | 40 | 范围 1–300 |
| 最大请求数 | 900 | 范围 50–20000 |
| User-Agent | `MatrixHunter/1.0 (authorized security assessment)` | 可自定义 |
| 代理 | 空 | 代理地址，例如 `http://127.0.0.1:8080`；留空直连 |
| 跳过 TLS 校验 | 开启 | 便于测试自签名证书；生产环境建议关闭 |
| 时间盲注 | 开启 | 更可靠但更慢；Quick 会强制关闭 |
| 侵入性检查 | 关闭 | 仅在明确授权时开启 |
| 回调域名 | 空 | 用于带外验证的可选回调域名 |
| 启用 AI 动态 Payload | 开启 | Web 扫描按主机加载 AI Payload 库 |
| AI 模型 | 自动 | 从可用免费模型中选择，可手动切换 |

修改设置后保存；部分设置只对之后启动的扫描生效。

### 告警

当出现新的 **严重 / 高危 / 中危已验证漏洞** 时：

- 按严重程度播放对应音频：`严重`、`高危`、`中危`。
- 每个漏洞连续播放 **3 次**；多个漏洞按队列依次播放。
- 界面保持红色闪烁边框，并弹出告警面板。
- 只有勾选“我已确认收到告警”并确认后才会停止。

内置音频位于 `%LOCALAPPDATA%\MatrixHunter\audio`。如需替换，在安装目录下创建 `mp3` 文件夹并放入：

```text
<安装目录>\mp3\严重.mp3
<安装目录>\mp3\高危.mp3
<安装目录>\mp3\中危.mp3
```

同名文件会覆盖内置音频。

### AI 动态 Payload

这是 1.0.4 的重点能力：让 AI 不再只“解释扫描结果”，而是根据真实攻击面动态生成 Payload 并做模拟攻击复核。

#### 工作流程

1. Web 扫描（GUI 或 AI 的 `vh_scan_web`）返回 `attack_surface`：
   ```json
   {
     "url": "https://example.com/item?id=1",
     "param": "id",
     "location": "query",
     "method": "GET"
   }
   ```
2. AI 根据参数名、页面上下文、历史线索，生成目标相关的验证型 Payload。
3. AI 调用 `vh_attack_probe`，指定目标、参数、类别和 Payload。
4. 本地确定性引擎执行请求并独立判断响应：
   - 只有可复现的真实证据才返回 `verified_findings`。
   - 没有证据时返回空结果，不会“猜测成功”。
5. 提交的 Payload 默认自动写入本机共享库（可用 `save=false` 关闭）；是否验证成功由引擎的返回结果单独决定：
   ```text
   %LOCALAPPDATA%\MatrixHunter\payloads.json
   ```
6. 后续同主机的 Web 扫描会自动加载该库并复用这些 Payload。

#### 支持的 Payload 类别

| 类别 | 验证方式 | 结果 |
| --- | --- | --- |
| `sqli` | 数据库错误指纹 / 时间盲注差异 | 可成为已验证漏洞 |
| `lfi` | 读取已知系统文件的真实内容签名 | 可成为已验证漏洞 |
| `ssti` | 模板算术表达式求值 | 可成为已验证漏洞 |
| `cmdi` | 回显随机 canary，反射不能伪造执行 | 可成为已验证漏洞 |
| `xss` | DOM 解析 + CSP 线索 | 严格口径下通常为线索 |

#### 安全限制

- XSS/CMDI 必须包含 `{{CANARY}}` 占位符，引擎会替换为随机值。
- CMDI 使用 `echo`/`printf` 回显探针，禁止破坏性命令、写文件、外联。
- 破坏性 SQL（如 `DROP`）、外联 LFI、危险命令会在请求前被拒绝。
- 每个参数、每个类别最多执行 3 条自定义 Payload；Quick 模式跳过。
- Payload 按主机隔离，不会跨目标复用。
- `attack_surface` 中的密码、Token、CSRF、邮箱、手机号等敏感表单字段会被剔除，不发送给 AI。

#### 开启/关闭

- GUI：在“实时扫描”页勾选/取消“启用 AI 动态 Payload（模拟攻击同步库）”。
- AI 自己的 `vh_scan_web` 会读取同一个共享库并自动复用。
- 关闭后，GUI Web 扫描不再加载 AI Payload；已保存的库不会被删除。

---

## MCP 工具

AI 通过内置 MCP 服务调用以下工具（OpenCode 中显示为 `vh_` 前缀）：

| 工具 | 作用 |
| --- | --- |
| `vh_ping` | 检查服务、版本与当前授权状态 |
| `vh_scan_web` | 对 Web 目标执行扫描，返回已验证漏洞、线索、`attack_surface` |
| `vh_scan_host` | 对主机执行端口/服务与未授权访问检查 |
| `vh_scan_source` | 对本地源码执行凭据与危险调用分析 |
| `vh_attack_probe` | 用 AI 生成的 Payload 对单个参数执行模拟攻击；可保存到共享库 |
| `vh_http_probe` | 执行只读 GET/HEAD 请求，用于安全复核 |
| `vh_get_findings` | 读取指定扫描的已验证漏洞与线索 |
| `vh_list_scans` | 列出历史扫描记录 |
| `vh_status` | 查看版本、授权状态、数据目录与扫描数量 |

所有会发起目标请求或执行扫描的工具都会校验当前会话授权；未授权时直接返回错误。`vh_ping`、`vh_get_findings`、`vh_list_scans`、`vh_status` 只读取本地状态或历史结果，不会发起新的扫描。

---

## 数据与文件位置

默认数据目录：`%LOCALAPPDATA%\MatrixHunter`

| 路径 | 内容 |
| --- | --- |
| `config.json` | 界面与扫描设置（不含持久授权） |
| `payloads.json` | AI 动态 Payload 共享库（按主机分组） |
| `scans\` | 每次扫描的 `.md` 与 `.json` 报告 |
| `logs\matrixhunter.log` | 运行日志、AI/sidecar 日志 |
| `agent\MATRIXHUNTER.md` | AI 作战指令 |
| `agent\opencode.json` | AI 服务的 MCP 配置 |
| `audio\` | 内置告警音频缓存 |
| `opencode-embedded\` | 内置 OpenCode 服务的隔离配置与会话数据 |

安装目录：

```text
<安装目录>\MatrixHunter.exe
<安装目录>\opencode-cli.exe
<安装目录>\mp3\严重.mp3   （可选覆盖）
<安装目录>\mp3\高危.mp3
<安装目录>\mp3\中危.mp3
```

> 扫描报告、日志和证据可能包含目标真实数据。分享前请脱敏，并遵守授权范围与数据保护要求。

---

## 常见问题

**Q：启动后界面空白 / 只有窗口没有内容？**

安装 Microsoft Edge WebView2 Runtime 后重启应用。Windows 11 通常已自带；Windows 10 若未安装，请从微软官网下载 Evergreen Runtime。

**Q：AI 一直显示“正在连接”或没有模型？**

- 确认 `opencode-cli.exe` 与 `MatrixHunter.exe` 在同一目录。
- 确认网络可以访问模型服务；免费模型可能临时限流。
- 查看 `%LOCALAPPDATA%\MatrixHunter\logs\matrixhunter.log` 中的 `ai`/`embedded` 日志。
- 在“系统设置”中重新选择模型，或稍后重试。

**Q：提示“未授权”或无法开始扫描？**

授权只在当前会话有效。关闭应用后需要重新打开授权弹窗，勾选两项确认后才能扫描。AI 的扫描与探针工具同样受此限制。

**Q：提示“已有扫描正在进行”？**

同一时间只允许一个扫描任务。等待当前任务完成，或在扫描页点击“停止扫描”。

**Q：为什么很多结果被过滤了？**

MatrixHunter 采用严格的补天数据危害口径。TLS、响应头、CORS、开放重定向、CRLF、TRACE、端口开放、版本号、目录列表等未证明数据泄露的问题会被过滤，并记录在 `filtered_items` 中。这是预期行为。

**Q：XSS 为什么只是线索？**

严格口径要求证明敏感数据泄露或会话/数据被实际读取。当前引擎能证明脚本可执行，但不会自动构造数据泄露链，因此 XSS 默认作为未验证线索，需人工确认。

**Q：AI 动态 Payload 没有生效？**

- 确认 Web 扫描页的“启用 AI 动态 Payload”已开启。
- 确认 AI 已经调用过 `vh_attack_probe` 并保存了 Payload。
- Payload 按主机隔离，目标主机必须与保存时一致。
- Quick 模式会跳过自定义 Payload；请使用 Standard 或 Deep。

**Q：没有告警声音？**

- 检查 Windows 音量和应用音量。
- 确认 `%LOCALAPPDATA%\MatrixHunter\audio` 下存在音频文件。
- 可在安装目录创建 `mp3\严重.mp3`、`高危.mp3`、`中危.mp3` 覆盖内置音频。
- 告警面板需要勾选“我已确认收到告警”才会停止，这是设计行为。

**Q：报告在哪里？**

`%LOCALAPPDATA%\MatrixHunter\scans\`，每次扫描生成 `<scan-id>.md` 和 `<scan-id>.json`。

**Q：如何彻底删除数据？**

卸载应用后，手动删除 `%LOCALAPPDATA%\MatrixHunter`。该目录包含扫描报告、日志、Payload 库和 AI 会话数据。

**Q：MSI 安装时提示未知发布者？**

当前安装包未做代码签名。请从可信来源获取，并在运行前校验文件哈希；企业环境建议先进行安全审核。

**Q：扫描很慢 / 请求很多？**

使用 Quick 降低页数与请求数，减小并发，或缩小目标范围。Deep 模式会主动扩展接口、备份路径和端口，耗时明显更长。

---

## 更新日志

### 1.0.4

- 新增 AI 动态 Payload：`vh_attack_probe` 按参数执行模拟攻击，确定性引擎独立验证。
- Web 扫描新增 `attack_surface`，AI 可针对真实参数生成 Payload。
- AI 保存的 Payload 按主机同步到后续 Web 扫描（GUI 与 AI 扫描共用）。
- 修复内置 OpenCode sidecar 的 Job Object 句柄问题，主程序退出/被强制结束后不会残留。
- `attack_surface` 自动剔除密码、Token、CSRF、邮箱、手机号等敏感表单字段。
- AI 作战指令与内置服务共享同一份文件，避免指令漂移。

---

## 安全与合规

- **只测试授权目标。** 使用前请取得目标所有者的明确书面授权，并严格遵守授权范围、时间窗口和测试方法。
- **授权不持久化。** 每次启动都需要重新确认；这是为了避免“一次授权、长期滥用”。
- **AI 会接触扫描上下文。** AI 对话和动态 Payload 会把工具返回的目标信息、证据片段发送给所选模型提供方。若目标数据敏感，请关闭 AI 功能，或仅在允许的数据范围内使用。
- **报告可能包含敏感数据。** 扫描证据、响应片段、个人信息示例可能出现在 Markdown/JSON 中，请按内部规范加密存储、限制访问。
- **不要用于破坏性测试。** 工具会拒绝明显破坏性的 AI Payload，但使用者仍须自行确保测试方法不会影响业务。
- **遵守当地法律与平台规则。** 未经授权的扫描、入侵、数据获取可能构成违法行为。

---

## 反馈

- Gitee 仓库：[https://gitee.com/AhangYa-AIEditRoom/MatrixHunter](https://gitee.com/AhangYa-AIEditRoom/MatrixHunter)
- GitHub 仓库：[https://github.com/AhangGameStudio/MatrixHunter](https://github.com/AhangGameStudio/MatrixHunter)
- 问题与建议：[GitHub Issues](https://github.com/AhangGameStudio/MatrixHunter/issues)

---

**MatrixHunter 1.0.4** · 用证据说话，让 AI 做验证，而不是做猜测。
