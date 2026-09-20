# Agent 生产化调研：运维 / 进版 / 上线

面向**平台/技术支持团队**的调研成果库：当公司内有多个业务部门自研 agent 要上生产环境时，平台团队该提供什么底座、什么门禁、什么流程。

## 文档

| 文档 | 说明 |
| --- | --- |
| [`agent-production-research.md`](agent-production-research.md) | **全景调研报告**（17 章）：12 条核心判断；生产化能力 10 层模型（L0 标准契约 → L9 事故响应）；各层方法论与开源项目选型（2026-09 实测 star / 版本）；AWS AgentCore / Azure Foundry / Google Agent Platform 对比；选型矩阵；6 个月落地路线图；14 条反模式 |
| [`agent-runtime-supervision-research.md`](agent-runtime-supervision-research.md) | **运行时行为可控性专项调研**（14 章）：把"领导怀疑 agent 不可靠"翻译成 6 个可回答的问题；**2026 年三大标准（ACS / AARM / ATF）**；13 个控制点模型与"单一咽喉点"契约；监督工具箱 P1–P6（契约校验 → 策略引擎 → 分类器 → 监督 agent → 形式化验证 → 人在环）；幻觉分型 H1–H5；跨框架 hooks/middleware 对照与阻断语义陷阱；运行期在线验证三形态（采样在线评测 / 定期金标集回放 / 对抗探针）；可靠性档案与分级授权；厂商与选型矩阵；15 条反模式 |
| [`otel-genai-introduction.md`](otel-genai-introduction.md) | **OpenTelemetry GenAI 详解**：为什么需要、与 OTel 主仓库的关系、开发状态与破坏性变更、Weaver 与一致性测试基建 |
| [`otel-genai-instrumentation-spec-v0.1.md`](otel-genai-instrumentation-spec-v0.1.md) | **公司内埋点规范 v0.1（Draft）**：基于上游约定的公司内子集与收紧规则，按 T0/T1/T2 分级强制 |

## 取证材料

| 路径 | 内容 |
| --- | --- |
| `research/gh_scan_1.txt`、`research/gh_scan_2.txt`、`research/gh_scan_eval.txt`、`research/gh_scan_guard.txt` | GitHub 实时检索结果（按主题，含 star 与最近提交时间） |
| `research/meta3.txt`、`research/meta4.txt`、`research/meta5.txt` | 运行时监督相关 100+ 项目的 star / 最新 release / 最近提交 / 许可证（2026-09-21 快照） |
| `research/vendor2/` | 厂商官方文档与标准原文（ACS、AARM、ATF、AWS/Azure/Google 护栏与评测、LangSmith、Langfuse、Claude Code hooks、OpenAI Agents SDK、ADK、Semantic Kernel、Anthropic Petri 等）——**不入库，可由脚本重新生成** |
| `research/meta.txt` | 56 个核心项目的 star / 最新 release / 最近提交 / 许可证 |

> 第三方项目的 README 原文与规范全文（抓取结果）未纳入版本库，可用下方脚本重新生成。

## 复现方式

```powershell
# 1) 拉取核心项目 README（写入 research/pages/）
powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch_pages.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch3.ps1

# 2) 抓取 OpenTelemetry GenAI 语义约定
powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch4.ps1

# 3) 抓取厂商官方文档（AWS / Azure / Google / LangSmith）
powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch5.ps1

# 4) 主题检索与项目元数据快照
powershell -NoProfile -ExecutionPolicy Bypass -File research/gh_scan.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/gh_scan2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/meta.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/meta2.ps1

# 5) 运行时监督专项（标准 / 护栏 / hooks / 在线评测 / 元数据）
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_runtime_control.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_runtime_control2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_fetch10.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_fetch11.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_fetch12.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/gh_scan_guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/meta3.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/meta4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File research/meta5.ps1
```

注：脚本需要访问 GitHub API 与 raw.githubusercontent.com。

## 时间

调研与数据快照：2026-09-17（全景报告）／2026-09-21（运行时监督专项）。star 数与版本号会随时间变化。
