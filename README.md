# Agent 生产化调研：运维 / 进版 / 上线

面向**平台/技术支持团队**的调研成果库：当公司内有多个业务部门自研 agent 要上生产环境时，平台团队该提供什么底座、什么门禁、什么流程。

## 文档

| 文档 | 说明 |
| --- | --- |
| [`agent-production-research.md`](agent-production-research.md) | **全景调研报告**（17 章）：12 条核心判断；生产化能力 10 层模型（L0 标准契约 → L9 事故响应）；各层方法论与开源项目选型（2026-09 实测 star / 版本）；AWS AgentCore / Azure Foundry / Google Agent Platform 对比；选型矩阵；6 个月落地路线图；14 条反模式 |
| [`otel-genai-introduction.md`](otel-genai-introduction.md) | **OpenTelemetry GenAI 详解**：为什么需要、与 OTel 主仓库的关系、开发状态与破坏性变更、Weaver 与一致性测试基建 |
| [`otel-genai-instrumentation-spec-v0.1.md`](otel-genai-instrumentation-spec-v0.1.md) | **公司内埋点规范 v0.1（Draft）**：基于上游约定的公司内子集与收紧规则，按 T0/T1/T2 分级强制 |

## 取证材料

| 路径 | 内容 |
| --- | --- |
| `research/gh_scan_1.txt`、`research/gh_scan_2.txt` | GitHub 实时检索结果（按主题，含 star 与最近提交时间） |
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
```

注：脚本需要访问 GitHub API 与 raw.githubusercontent.com。

## 时间

调研与数据快照：2026-09-17。star 数与版本号会随时间变化。
