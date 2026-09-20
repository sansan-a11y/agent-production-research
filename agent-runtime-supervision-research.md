# Agent 运行时行为可控性调研：监督者 / 钩子 / 在线验证

> 调研时间：2026-09-21　|　视角：**平台/技术支持团队**（为多业务部门自研 agent 提供运行时控制底座）
> 要回答的质疑：**"我的 agent 到底在干什么、会不会胡说、出了事能不能刹住、怎么证明？"**
> 数据来源：GitHub API 实测（star / 最新 release / 最近提交 / 许可证，快照见 `research/meta3.txt` `meta4.txt` `meta5.txt`）+ 厂商官方文档 + 标准原文（抓取全文见 `research/vendor2/`、`research/pages4/`）
> 前置文档：[`agent-production-research.md`](agent-production-research.md)（L0–L9 全景）。本篇是其中 **L3.5「运行时监督」** 的专项深挖，可独立阅读。

---

## 0. 摘要：14 条核心判断

1. **"运行时控制"在 2026 年已经有标准了**，不再是各家自创：**ACS（Agent Control Standard）** 定义"中间件钩子 + Guardian Agent + 判定结果（allow / deny / modify）"；**AARM**（Cloud Security Alliance 项目）定义运行时拦截的 6 条 **MUST** 要求；**ATF**（Agentic Trust Framework）定义"自主权分级"。**回答领导最省力的方式，就是直接引这三份文档而不是讲自研方案**（§2）。
2. **可靠性不能靠单一检测器。** 正确形态是四层纵深：契约校验（确定性）→ 策略引擎（确定性）→ 分类器/判官（概率性）→ 人在环（兜底），外接事后验证闭环。任何"用一个超级审查 agent 兜住一切"的方案都会在延迟、成本、误报率上崩掉（§4、§12.1）。
3. **性价比最高的一层是确定性校验**：工具白名单 + JSON Schema/受限解码 + 参数范围与权限校验，**零额外模型调用**即可拦掉大部分"工具调用幻觉"。监督 agent 只应处理确定性规则表达不了的语义问题（§4.1、§4.2）。
4. **"所有工具调用必须经过单一咽喉点（choke point）"是平台团队最该强制的契约。** 只要工具调用（含 MCP、子 agent、代码执行）全部经过同一个拦截点，就能一次性获得：策略拦截、审计留痕、PII 脱敏、影子/干跑、评测采样（§3.3、§6.4）。
5. **"工具调用幻觉"与"内容幻觉"是两类问题，必须分开度量。** IBM Granite Guardian 4.1 已把 `function-call hallucination` 与 `groundedness` 做成**预置判据**；AWS Bedrock 有 contextual grounding check；Azure 有 Groundedness detection（含自动纠正）与 **Task Adherence**（专查"工具调用与用户意图不一致"并给出理由、输出阻断信号）（§5、§9.1–9.3）。
6. **证据力最强的是形式化验证。** AWS Bedrock Guardrails 的 **Automated Reasoning checks** 用数学证明判断回答是否与策略矛盾，并给出"为什么正确/错误"的可验证解释，还能指出**未明说的假设**。金融/医疗等合规场景的关键断言值得用它（§4.5）。
7. **监督者本身会幻觉、judge 本身有偏差。** 因此工程上必须做到：确定性优先、概率性兜底、监督失效时**显式选择** fail-open / fail-closed（高危必须 fail-closed）、并定期用有标签的数据集校准 judge（§4.7、§5.4）。
8. **阻断语义里有坑。** OpenAI Agents SDK 的输入护栏默认**并行执行**（`run_in_parallel=True`），护栏判定为违规时**工具可能已经执行完**；要"先拦后放"必须显式使用 blocking 模式。类似差异在各框架普遍存在（§6.2）。
9. **运行期在线验证有三种形态，别混为一谈**：① **采样在线评测**（对线上 trace 打分）② **定期金标集回放**（synthetic canary：用生产版本跑固定测试集）③ **对抗探针**（注入/红队/越权）。三者互补，缺一不可（§7.1）。
10. **在线评测已经产品化，不必自建。** LangSmith Online Evaluators（过滤 + 采样率 + 周花费上限 + 历史回填）、Langfuse LLM-as-a-judge、Datadog LLM Observability、W&B Weave **Signals**（每条生产 trace 自动行为打分）、Opik、Braintrust、Phoenix、Laminar 等（§7.2，含 2026-09 实测版本）。
11. **在线评测成本必须预算化。** 建议评测开销 ≤ 该 agent 自身推理成本的 10–20%；采样率建议 T0 约 1%、T1 约 5–10%、T2 约 20–100%（§7.5，属工程估算而非实测数据）。
12. **商用市场正在整合，别押注单点产品。** Galileo 自 **2026-08-07** 起并入 **Splunk Agent Observability**；此外 Prompt Security→SentinelOne、CalypsoAI→F5、Protect AI / HiddenLayer→Palo Alto Networks、Humanloop 团队→Anthropic。选型应挑"平台能力"（§9.4）。
13. **国内可私有化选项**：**Qwen3Guard**（阿里开源审核模型：生成式 + 流式、三档严重度、119 语言）、**腾讯 AI-Infra-Guard**（红队平台：Agent Scan / Skill Scan / MCP Scan / 越狱评测，Apache-2.0）。内网/数据不出域场景这两条最关键（§9.5）。
14. **要让领导"信"，交付物不是架构图，而是"可靠性档案"**：每次发布附评测通过率、对抗通过率、在线监控窗口结果、事故与回归记录；并按 ATF 的 4 级自主度**逐步放权、可随时降级**（§8）。

---

## 1. 问题定义：把"可靠性怀疑"翻译成可回答的 6 个问题

领导的怀疑通常表现为一句模糊的话："agent 说错话/乱调工具怎么办？" 工程上要把它拆成 6 个可回答、可度量的问题。**这 6 问也是本报告的目录逻辑。**

| # | 领导的问题 | 工程问题 | 本报告对应 | 度量指标（建议进 SLO） |
| --- | --- | --- | --- | --- |
| Q1 | 它会不会**乱调工具**？ | 工具选择与参数是否合法、是否越权、是否与用户意图一致 | §3–§6 | `tool_call_hallucination_rate`、`policy_violation_rate` |
| Q2 | 它会不会**胡说**？ | 输出是否被上下文/工具结果支撑（groundedness） | §5 | `groundedness_score`、`unsupported_claim_rate` |
| Q3 | 它会不会**跑偏**？ | 计划是否偏离任务目标、步数/成本是否失控 | §3.2、§7.4 | `plan_adherence`、`steps_per_task`、`cost_per_task` |
| Q4 | 出事能**立刻刹住**吗？ | 是否有 kill switch、熔断、只读降级、人工接管 | §4.6、§8.3 | `MTTD`（发现时间）、`MTTK`（刹车时间） |
| Q5 | 能**证明**发生了什么吗？ | 决策级审计：用了哪条策略、为什么放行/拒绝 | §8.2 | 审计完整率、可回放率 |
| Q6 | 能力**在退化**吗？ | 定期在线验证 + 漂移检测 + 回归集 | §7 | `regression_pass_rate`、`drift_delta` |

### 1.1 把"可控性"定义清楚：四个属性

一个 agent 只有同时具备下面 4 个属性，才谈得上"可控"：

- **可干预（Intervenable）**：在动作落地**之前**有确定性的拦截点（不是事后分析）。
- **可验证（Verifiable）**：有独立于"agent 自己说"的检查手段（规则、判官、形式化证明、人工抽检）。
- **可解释（Explainable）**：每个被拒绝的动作能给出**理由**与命中的规则。
- **可回滚（Rollbackable）**：版本、策略、记忆、在途任务都能退回去。

> **一句话向领导对齐**：我们不承诺 agent 永不犯错，我们承诺**错误在落地前被拦住的比例**、**错误发生后被发现的时间**、**每次决策的可追溯性**——这三个是可承诺、可度量的。

### 1.2 一个必须接受的现实

prompt 层面的"请你遵守规则"**不是控制面**（微软 Agent Governance Toolkit 自己的表述：*"Prompt-level safety is not a control surface"*）。模型层的防御是概率性的，红队研究显示自适应攻击可达到很高的成功率。因此控制必须下沉到**代码/网关/策略层的确定性执行**。

---

## 2. 参照系：2026 年成型的三个标准（本篇最重要的发现）

过去一年"运行时监督"从各家自研走向标准化。**这三份文档建议直接进入公司标准库**，因为它们同时解决了"怎么做"和"怎么给领导/审计解释"。

### 2.1 ACS — Agent Control Standard（运行时控制面的接口标准）

- **定位**：*"The runtime control plane for AI agents"* —— 定义 **agent 平台如何暴露中间件钩子（hooks）**，以及**开源工具如何通过这些钩子执行安全策略**。
- **核心模型（三层）**：
  - **Tier 1 平台层**：平台在**每个决策点**暴露标准钩子——输入、输出、工具调用、工具响应、**规划→执行的转换**、记忆读写、生命周期。*"平台不需要理解或实现控制规范，它只需要暴露钩子。"*
  - **Tier 2 执行层**：框架无关的 SDK 读取声明式策略，在钩子上执行：输入校验、工具调用授权、输出过滤、对抗检测。
  - **Tier 3 企业层**：自定义分类器/领域检测器（金融的数据敏感度、医疗的 PHI）插进执行层，无需改动平台。
- **Guardian Agent + 三种判定**：动作到达生产系统前被拦截，返回 **allow / deny / modify** 三种 verdict。
- **配套**：Trace（扩展 OpenTelemetry 语义约定 + 映射 **OCSF** 供 SIEM 消费）、Inspect（**AgBOM**：动态 Agent Bill of Materials，扩展 CycloneDX/SPDX/SWID）。
- **治理**：Apache-2.0，OWASP 生态，与 OWASP ASI、AIVSS、OpenTelemetry、MCP、A2A 对齐。
- **对我们的价值**：可直接当作**平台团队要求业务侧框架支持的最小钩子契约**（§6.4），避免"每个部门一套拦截逻辑"。

### 2.2 AARM — Autonomous Action Runtime Management（运行时安全的系统类别规范）

- **归属**：Cloud Security Alliance（CSA）项目，*"The system category specification for agentic runtime security"*。
- **两级符合性**：
  - **AARM Core（R1–R6，全部 MUST）**：从**执行前拦截（pre-execution interception）到身份绑定**的基线。
  - **AARM Extended（R1–R9）**：增加**语义漂移跟踪（semantic drift tracking）**、遥测导出、最小权限。
- **11 类威胁（可直接用作威胁模型清单）**：prompt injection、数据外泄、confused deputy、目标劫持（goal hijacking）、记忆投毒、**意图漂移（intent drift）**、跨 agent 传播、权限过大、侧信道泄漏、环境操纵、**恶意工具输出**。
- **生态**：官网称 107 家厂商登记；已完成正式符合性审查的包括 Microsoft Agent Governance Toolkit（Extended）、Noma Security、Operant AI、Highflame、Airia、MintMCP、QuilrAI、Runlayer 等。
- **对我们的价值**：**"我们要过 AARM Core"是一句能被审计听懂的话**；11 类威胁可直接变成评测集的分类维度。

### 2.3 ATF — Agentic Trust Framework（自主权分级治理标准）

- **五个核心要素**：**身份**（谁）、**行为**（在做什么）、**数据**（进出的数据）、**分段**（能去哪里）、**响应**（失控怎么办）。
- **四级自主度（这是给领导最好用的沟通工具）**：
  | 级别 | 名称 | 自主性 | 监督方式 | 例子 |
  | --- | --- | --- | --- | --- |
  | L1 | Intern | 只读 | 持续观察 | 监控日志、标记可疑模式 |
  | L2 | Junior | 只建议 | 每个动作都要人批准 | 起草回复等人工确认后发送 |
  | L3 | Senior | 在护栏内行动 | 事后通知 | 自动扩容并通知运维 |
  | L4 | Principal | 边界内自主 | 战略级 + 边缘案例升级 | 按 playbook 处置事件，新型威胁升级 |
- **核心原则**：*"Autonomy is earned, not granted"* —— 升级需要**持续准确性 + 干净的 incident 记录 + 通过的安全审计 + 明确的治理签字**；**出事故可以降级**。
- **许可**：CC BY 4.0（CSAI Foundation）。
- **对我们的价值**：把"我们要不要信任这个 agent"变成**流程问题**而不是技术争论。建议写进 agent manifest：`autonomy_level: L2` + 升级条件 + 降级触发条件。

### 2.4 相关合规/威胁框架的对照

| 框架 | 作用 | 与本篇的关系 |
| --- | --- | --- |
| **OWASP Top 10 for Agentic Applications 2026**（2025-12-09 发布，100+ 专家评审） | 威胁清单 | 威胁模型与评测集分类的起点 |
| OWASP LLM Top 10 (2025) | LLM 应用风险 | 与 agentic 版互补（LLM01 prompt injection 等） |
| MAESTRO | 7 层威胁建模 | 与 ATF/AARM 的控制项配合 |
| NIST AI RMF（+ Generative AI Profile） | 治理流程（Govern/Map/Measure/Manage） | 持续监控、可停用能力的依据 |
| EU AI Act | 高风险管理体系 | 要求**可证明的人工监督与实时干预能力** |
| ISO/IEC 42001 | AI 管理体系（可认证） | 若需对外证明治理成熟度 |
| AWS Agentic Scoping Matrix | 自主度分级 | ATF 四级可直接映射到 Scope 1–4 |

> **给领导的一段话**：行业已经就"需要运行时可见性 + 干预能力 + 可审计控制"达成一致（ACS/AARM/ATF/OWASP/EU AI Act 说法一致），分歧只在实现。**我们按 ACS 暴露钩子、按 AARM 做拦截、按 ATF 决定放权级别**，就是照标准落地，而不是自己发明。

---

## 3. 控制点模型：一个 agent 运行到底有几个地方可以"管"

### 3.1 13 个控制点

把一次 agent 运行拆开，可插钩子的位置是有限的（这也是 ACS 的 Tier 1 清单）：

| # | 控制点 | 典型时机 | 能拦什么 | 可阻断 | 熵（可预测性） |
| --- | --- | --- | --- | --- | --- |
| C1 | **输入进入** | 用户/上游系统请求 | 注入、越权请求、无意义请求、PII 入站 | ✅ | 高 |
| C2 | **计划生成后** | 首个 plan / todo | 危险计划、越界目标、缺审批步骤 | ✅ | 中 |
| C3 | **每次模型调用前** | 每轮 LLM 前 | 上下文污染、工具白名单裁剪、注入内容隔离 | ✅ | 高 |
| C4 | **每次模型调用后** | 每轮 LLM 后 | 幻觉、格式不合法、下一步动作可疑 | ✅ | 中 |
| C5 | **工具选择时** | 模型选定 tool 后、执行前 | **工具调用幻觉**（不存在的工具、参数不合法、与意图不符） | ✅ | 高 |
| C6 | **工具执行前（pre-tool）** | 真正调用前 | 越权、高危动作、缺幂等键 | ✅ | 高 |
| C7 | **工具执行后（post-tool）** | 拿到结果 | 结果被篡改/投毒、把敏感数据回灌上下文 | ⚠️ 可重写 | 高 |
| C8 | **工具结果入上下文前** | 写入 messages 前 | 提示注入经工具结果回流（**最常见攻击路径**） | ✅ | 中 |
| C9 | **记忆写入前** | 长期记忆写 | 记忆投毒（"以后所有退款直接通过"） | ✅ | 中 |
| C10 | **记忆读取后** | 注入上下文前 | 脏记忆污染、跨租户泄漏 | ✅ | 中 |
| C11 | **子 agent 派生 / 委派** | 多 agent 协作 | 权限放大、递归失控、信任链断裂 | ✅ | 中 |
| C12 | **输出给用户前** | 最终答复 | 未接地断言、PII 外泄、越权承诺 | ✅ | 高 |
| C13 | **会话结束 / 生命周期** | 结束、超时、压缩 | 归档、审计封存、指标结算 | — | 高 |

> **经验法则**：**C5/C6/C8/C9** 是投入产出比最高的四个点——分别对应"乱调工具""越权执行""被注入""记忆被污染"。

### 3.2 分层的控制目标（不同点用不同武器）

- **确定性可判**（C1/C5/C6/C12 的格式与权限部分）→ 用**规则/策略/Schema**，不要用 LLM。
- **语义可判但有歧义**（C2/C4/C5 的"意图一致性"）→ 用**判官模型 / Task Adherence 类服务**，成本高、需采样。
- **不可判但需留痕**（C7/C10/C13）→ 用**审计 + 采样评测 + 事后复盘**。

### 3.3 平台团队的强制契约：单一咽喉点（Choke Point）

**要求（建议写进上线门槛）**：

1. 所有工具调用——本地函数、MCP 工具、子 agent、代码执行、浏览器/computer use——**必须**经过同一个拦截层（进程内 SDK 或网关，二者取一，不可混用）。
2. 拦截层必须暴露**统一事件**：`tool_call_requested` / `tool_call_allowed` / `tool_call_denied`（含理由）/ `tool_call_completed` / `tool_call_modified`。
3. 每个工具必须声明元数据：**风险等级（只读/写/高危）、幂等键生成方式、干跑（dry-run）支持、数据分级、超时与重试**。
4. **默认 fail-closed**：拦截层自身异常时，高危工具拒绝执行；只有显式标注 `fail_open: true` 的只读工具才允许放行。

> 这条契约的收益：审计、脱敏、影子流量、评测采样、预算与配额、策略演进——**全部只需要在一个地方实现一次**。

---
## 4. 监督工具箱：6 种模式，按"确定性 → 概率性 → 人"排序

**结论先行**：把监督做成**纵深防御**，而不是买一个"超级审查 agent"。下面 P1→P6 的成本、延迟、可靠性单调变化，**正确姿势是从 P1 开始往上加，而不是从 P5 开始往下砍**。

| 模式 | 延迟 | 成本 | 覆盖面 | 误报 | 证据力 | 适用控制点 |
| --- | --- | --- | --- | --- | --- | --- |
| **P1 契约校验**（Schema/白名单/范围） | ~0 | 0 | 工具调用合法性 | 极低 | 强（确定性） | C1/C5/C6/C12 |
| **P2 策略引擎**（Cedar/OPA/CEL） | ~0–5ms | 0 | 越权、边界、配额 | 低（需写对策略） | 强（确定性 + 可解释） | C2/C5/C6/C11 |
| **P3 分类器/审核模型** | 10–200ms | 低（小模型自托管） | 注入、有害、忠实度 | 中 | 中（概率性） | C1/C4/C8/C12 |
| **P4 监督 agent / LLM-judge** | 0.5–10s | 中–高 | 语义级意图一致性 | 中–高 | 中（需校准） | C2/C4/C5/C12 |
| **P5 形式化验证** | 秒级（离线/准在线） | 中 | 策略相关的事实性断言 | 低（在策略覆盖范围内） | **最强（数学证明）** | C4/C12 |
| **P6 人在环** | 分钟–小时 | 人力 | 一切（但不可扩展） | 低 | 强（有签字） | C6/C11 |

### 4.1 P1：契约校验（先用 0 成本吃掉大头）

**必须做的 6 件事**（全部零额外模型调用）：

1. **工具白名单**：模型只能看到"本次任务允许的工具子集"（按角色/租户/任务裁剪），从根上消灭"调用不存在的工具"。
2. **结构化输出 + 受限解码**：工具参数一律走 JSON Schema / pydantic / GBNF 约束解码，参数类型错误在生成阶段就不可能产生。
3. **参数语义校验**：范围、枚举、外键存在性、日期合理性、金额上限（例如"退款金额 ≤ 原订单金额"）。
4. **幂等键**：写类工具必须带幂等键（从 `tool_call_id` 派生），重试不会重复下单。
5. **干跑模式**：每个写类工具提供 `dry_run=true`，用于影子流量与在线验证（否则影子流量会产生真实副作用）。
6. **步数与预算上限**：最大步数、最大工具调用次数、最大子 agent 深度、单任务成本上限。

### 4.2 P2：策略引擎（把"能不能做"从 prompt 里搬出来）

**关键原则**：策略必须是**声明式、确定性、可测试、可版本化**的，而不是提示词。

| 方案 | 说明 | 实测状态（2026-09-21） |
| --- | --- | --- |
| **Cedar** | AWS 用于 Bedrock AgentCore Policy 的策略语言；**每一次工具调用**都在网关侧做确定性判定 | `cedar-policy/cedar` 1.7k★，`cedar-policy-cli-v4.13.0` |
| **OPA / Rego** | 通用策略引擎，生态最成熟 | `open-policy-agent/opa` 12.3k★，v1.20.2 |
| **CEL** | 轻量表达式，AI 网关常用（agentgateway 的 CEL RBAC） | agentgateway 4.9k★，v1.5.0 |
| **授权引擎** | 工具级"谁能对什么做什么" | `openfga/openfga` 5.8k★ v1.21.0；`cerbos/cerbos` 4.6k★ v0.55.0 |
| **一体化治理 SDK** | 两行代码包住任意工具函数 | `microsoft/agent-governance-toolkit` **6.3k★，MIT，2026-09-20 仍在提交** |

**Agent Governance Toolkit（AGT）值得单列**，因为它把本篇要的能力打成了"可安装的一套"，并写明了设计取舍：

- **拦截点在应用代码里**：*"Every tool call, message send, and delegation is intercepted in deterministic application code before the model's intent reaches the wire."* 被拒绝的动作不是"不太可能"，而是**结构上不可能**发生。
- **组件**：Policy Engine / Identity（Ed25519、执行环）/ **Agent Hypervisor**（执行审计、delta engine、命令黑名单）/ **Agent SRE**（kill switch、SLO 监控、混沌测试、熔断）/ Merkle 审计链 / **Decision BOM（可重建的决策账单）**。
- **值得抄的 ADR**：**ADR-0013 Fail Closed on Errors**、**ADR-0014 Parent Deny Immutable**（父级拒绝不可被下级覆盖）、**ADR-0017 Merkle Audit Chain**、**ADR-0018 Reconstructible Decision BOM**、**ADR-0020 Circuit Breaker for Sinks**。
- **合规映射**：OWASP ASI 2026 参考架构（自述覆盖 OWASP Agentic Top 10 的 7 项完整 + 3 项部分）、NIST AI RMF、EU AI Act、SOC 2、ISO/IEC 42001、CSA ATF、CIS v8.1。
- **注意**：仓库标注 **Public Preview**（GA 前可能有破坏性变更）；作为"范式参考 + 试点"合适，不建议直接承接 T2 关键链路。

### 4.3 P3：分类器 / 审核模型（快、便宜，但只覆盖"已知类别"）

| 模型/工具 | 定位 | 实测状态 | 备注 |
| --- | --- | --- | --- |
| **Llama Guard 4** | 输入/输出护栏，基于 **MLCommons** 政策 | `meta-llama/PurpleLlama` 4.4k★ | 官方定位即"input and output guardrails for LLM deployments" |
| **LlamaFirewall** | **为 agent 设计的开源护栏框架**：PromptGuard 2（注入分类器）+ **AlignmentCheck**（审计**思维链**，检测目标劫持/间接注入）+ CodeShield（生成代码静态分析）+ 正则/自定义扫描器 | 同上仓库 | 明确是"policy engine 编排多个 scanner"，可插到 agent 工作流的多个阶段，面向**多步 agent** |
| **Qwen3Guard** | **Gen**（整段判定）+ **Stream**（token 级实时判定）；0.6B/4B/8B；**三档严重度**（safe/controversial/unsafe）；**119 语言**；119 万条标注训练 | `QwenLM/Qwen3Guard`（511★，2025-10） | **国内可私有化 + 流式**是最大优势（对话中拦截，而不是说完才拦） |
| **Granite Guardian 4.1** | **判据式判官模型**：预置 `groundedness`、**`function-call hallucination`**、harm、jailbreak、bias 等；支持 **BYOC**（自定义判据，含格式/长度/领域规则）；`<think>` / `<no-think>` 两种模式（延迟 vs 可解释） | `ibm-granite/granite-guardian`（178★，Apache-2.0，模型在 HF） | **对"agent 时代"最对症**：官方明确覆盖"tool calls 与 RAG 的幻觉" |
| **NeMo Guardrails** | 可编程 rails：**input / dialog / output / execution / retrieval** 五类，DSL 为 Colang；与 LangChain 集成 | `NVIDIA-NeMo/Guardrails` 7.2k★（**仓库已从 NVIDIA/NeMo-Guardrails 迁移**） | 表达能力强，但要写 Colang，学习成本高 |
| **Guardrails AI** | Validator 生态（Hub），可组合、可复用到 CI | `guardrails-ai/guardrails` 7.4k★，v0.11.0（最近提交 2026-09-18） | 已有事实核查类 validator（如 MiniCheck）可直接挂 |
| **Model Armor / Azure AI Content Safety** | 托管式输入输出筛查（含清洗/纠正） | Google Cloud / Azure 官方文档已取证 | 无需自运维模型，适合业务部门直接用 |
| **llm-guard** | 通用 LLM 安全工具包 | `protectai/llm-guard` 3.2k★，最近提交 **2026-07-08** | 活跃度一般，新项目建议评估替代 |

### 4.4 P4：监督 agent / LLM-as-judge（解决语义问题，但要防"裁判也瞎"）

- **产品化范例：Azure AI Content Safety 的 Task Adherence（preview）**——"监督 agent 查工具调用"最直接的商品化形态，官方描述：
  - 检测 *"misaligned tool invocations, improper tool input or output relative to user intent, and inconsistencies between responses and customer input"*；
  - **为不一致给出理由（reasoning）**；
  - 输出**信号**用于 *"downstream tool invocation blocking and escalation to human-in-the-loop review"*；
  - 场景举例：在执行后端工具调用**之前**校验 agent 的计划。
  > 结论：**"执行前用另一个模型校验工具调用是否与用户意图一致"已经被云厂商做成标准服务**，自研不是唯一解。
- **研究侧**：`metauto-ai/agent-as-a-judge`（827★）把"用 agent 评 agent"形式化；Anthropic **Petri**（2025-10 开源）用自动化审计 agent + 模拟用户/工具做多轮探测并打分，已用于 Claude 4 系列 system card。运行时厂商 Adrian 引用 OpenAI/DeepMind 研究（arXiv:2503.11926）主张：**同时看"动作 + 推理轨迹"比只看动作显著更准**（其自述 +35% 检测准确率，属厂商口径）。
- **必须知道的偏差**：LLM-as-judge 存在**位置偏差、冗长偏好、自偏好**，且 judge 本身会幻觉。**缓解**：固定 rubric、成对比较时随机交换位置、多 judge 投票、用有标签集定期校准（§5.4），并给它**独立预算与超时**。
- **三种工程形态**：
  1. **同步阻塞式**：在 C5/C6 阻塞，不合格不放行（延迟敏感场景慎用）。
  2. **异步旁路式**：不阻塞主流程，后台打分 + 告警/降级（最常用）。
  3. **分流式**：监督 agent 只做分流，把可疑样本送人审（成本可控）。

### 4.5 P5：形式化验证（证据力天花板）

**AWS Bedrock Guardrails — Automated Reasoning checks（已核对官方文档）**：

- 用**形式逻辑**验证自然语言内容是否与你定义的**策略**一致，而不是模式匹配。
- 能做三件事：① 通过与策略规则矛盾**数学证明**出事实性错误；② 指出 *"consistent with your policy but doesn't address all relevant rules"* 这类**未明说假设/不完整**；③ 给出 *"mathematically verifiable explanations"*，引用具体策略规则与变量取值。
- 官方定位：*"verification layer that provides detailed, actionable feedback"*，而非二元闸门；**面向受监管行业**（医疗、人力、金融）。

> **用法建议**：不要试图覆盖全部输出（成本高、需要建模）。**只对关键断言做形式化验证**（金额、资格判定、合规结论、医疗建议边界），其余走 P3/P4。这是"给审计看"的最强证据。

### 4.6 P6：人在环（HITL）——兜底，但要"便宜地兜底"

| 机制 | 实现 | 实测状态 |
| --- | --- | --- |
| **LangChain `HumanInTheLoopMiddleware`** | 按工具名配置 `interrupt_on`，命中即中断等人工批准 | LangChain 146.7k★（`langchain-core==1.6.3`） |
| **LangGraph Interrupts** | 动态中断 + `Command(resume=...)` 恢复；可一次恢复多个中断（按 interrupt id 配对） | `langchain-ai/langgraph` 42.0k★ |
| **OpenAI Agents SDK 审批** | `needs_approval=True` 或按调用判定；暂停后 `RunResult.interruptions` 列出待批项；**参数无法安全解析时视为需要人工批准（fail closed）**；支持 Run 级/单次自定义拒绝话术 | `openai/openai-agents-python` 29.6k★，v0.22.3 |
| **Claude Code / Agent SDK 权限** | `PermissionRequest` 钩子可**代用户放行或拒绝**；SDK 里 `PreToolUse` 钩子返回 `permissionDecision: deny` + 理由 | `anthropics/claude-code` 147k★；SDK 支持 hooks + 自定义工具 |
| **长事务审批** | 审批可能跨越数小时/数天，需要持久化执行（崩溃续跑、超时升级） | Temporal 23.2k★ v1.32.0；Restate 4.4k★；Inngest 5.9k★；Hatchet 8.0k★；DBOS 1.6k★ |
| **可验证审批记录** | 审批与执行记录**离线可逐字节验证**（审计场景） | `open-multi-agent/open-multi-agent` 6.9k★：*"consequential actions wait for durable, tamper-evident approvals"* |
| **刹车** | kill switch / 熔断 / 只读降级 | AGT Agent SRE；Highflame 的 "agent kill switch with instant revocation"（AARM 厂商名单） |

**HITL 工程要点**：① 审批要有**超时策略**（超时=拒绝还是升级？高危默认拒绝）；② 审批界面要给**证据**（工具参数、命中策略、监督 agent 的理由）；③ 审批决策要**回写评测集**（人的判断是最贵的标注）；④ 审批率本身是 SLO（`escalation_rate`），过高说明规则/阈值需要调。

### 4.7 "谁监督监督者"：三条硬规则

1. **监督失败必须显式声明语义**：`fail_open` 仅限只读工具；写/高危一律 `fail_closed`（对应 AGT ADR-0013）。
2. **监督者要有独立预算与超时**，不能因为监督慢拖垮主流程（对应 AGT ADR-0020 熔断）。
3. **定期校准**：维护一个带标签的"监督评测集"（含真实误报/漏报样本），**把监督者当成一个需要回归测试的模型**来管。

---
## 5. 幻觉要分型，才能对症下药

**这是多数团队做错的地方**：把"幻觉"当成一个指标，于是选了一个通用判官模型，结果既误报又漏报。

### 5.1 五种幻觉 × 检测手段

| 类型 | 定义 | 典型表现 | 首选检测 | 备注 |
| --- | --- | --- | --- | --- |
| **H1 工具调用幻觉** | 工具/参数与意图不符 | 调不存在的工具、参数编造、日期/金额虚构、选错工具 | **P1 契约校验**（白名单 + Schema + 范围） | 最容易被确定性手段消灭 |
| **H2 工具结果幻觉** | 编造或曲解工具返回 | 报"查到 3 条记录"但工具返回 0 条；把错误当成功 | **结果比对**（原始返回 vs 断言）+ Granite Guardian 的 function-call 判据 | 前提是把工具**原始返回**保留在 trace 里 |
| **H3 知识幻觉** | 无依据的事实断言 | 政策、数额、条款、时间说错 | 领域判官 / **形式化验证（P5）** / 强制引用 | 高风险域建议"无来源不得断言" |
| **H4 接地幻觉（grounding）** | 与给定来源不一致 | RAG 摘要引入来源中没有的信息 | **Contextual grounding check**（AWS：grounding + relevance 两维，带**置信度与阈值**）/ Groundedness detection（Azure，**支持自动纠正**）/ HHEM、MiniCheck、RefChecker、UQLM | 有专用小模型，便宜 |
| **H5 行为幻觉** | 做了未被要求/超出授权的事 | 擅自发邮件、下单、改配置 | **策略引擎 + Task Adherence + 审批** | 最危险，必须确定性拦截 |

### 5.2 "接地"这件事的可选件（按成本从低到高）

| 工具 | 类型 | 实测状态 | 说明 |
| --- | --- | --- | --- |
| **HHEM / Vectara 榜单** | 基准 | `vectara/hallucination-leaderboard` 3.3k★（最近提交 2026-05-11） | 摘要类幻觉横向对比，用于选型 |
| **MiniCheck / Bespoke-MiniCheck-7B** | 小模型事实核查 | `Liyan06/MiniCheck` 226★（EMNLP 2024）；**LLM-AggreFact** 榜单（聚合 11 个数据集） | 自称 SOTA 且**可商用**；已作为 Guardrails AI validator，可本地 ollama 跑 |
| **RefChecker** | 细粒度核查 | `amazon-science/RefChecker` 434★ | 三元组级（claim–evidence）幻觉检测 |
| **SelfCheckGPT** | 黑盒一致性 | `potsawee/selfcheckgpt` 631★，最近提交 **2024-06** | 经典方法但**已不再活跃**，新项目慎用 |
| **UQLM** | 不确定性量化（做"拒答/转人"触发器） | `cvs-health/uqlm` **1.2k★，Apache-2.0，JMLR 2026** | 五类 scorer：黑盒（多次生成一致性，慢且贵）、**白盒（token 概率，成本≈0）**、LLM-judge、ensemble、长文本（claim 级）；官方给了延迟/成本对照表 |
| **托管服务** | 省事 | AWS contextual grounding（**上限：来源 10 万字符 / 查询 1000 / 响应 5000**；流式场景下"不相关"可能**在流完之后**才被标记）、Azure Groundedness（可纠正） | 注意流式场景的判定时机 |

> **UQLM 的白盒 scorer 值得单独注意**：直接用 token 概率做不确定性估计，**几乎零延迟零成本**，非常适合做"低置信度 → 自动转人工"的触发器，比再跑一个 judge 模型划算。

### 5.3 建议的"幻觉指标"（可进 SLO）

```
tool_call_hallucination_rate  = H1 失败次数 / 工具调用总数      （目标：< 0.5%）
ungrounded_claim_rate         = 未接地断言数 / 断言总数        （按域设定，需人工抽检校准）
policy_violation_rate         = 策略拒绝数 / 动作总数          （目标接近 0；突增 = 攻击或回归）
escalation_rate               = 转人工数 / 任务总数            （过高=规则过严；过低=监督失效）
judge_disagreement_rate       = judge 与人审不一致比例         （监控 judge 漂移）
```

### 5.4 校准方法（让指标可信）

1. 每周抽 **30–100 条**线上样本做**人工标注**（分层抽样：拒绝样本、转人工样本、随机样本）。
2. 计算判官与人工的一致率（如 Cohen's κ），低于阈值就**调 rubric/换模型**，而不是继续信任分数。
3. **把误报也当缺陷管理**：误报会推高 `escalation_rate`，最终导致业务侧绕过控制——这是控制系统失效的头号原因。

### 5.5 评测/基准清单（用于"定期在线验证"的测试集来源）

| 基准 | 测什么 | 实测状态 |
| --- | --- | --- |
| **τ²-bench（τ-bench 后续）** | 工具-智能体-用户三者交互的**真实域**任务 | `sierra-research/tau2-bench` 2.1k★，v1.0.1（2026-09-19 仍在提交） |
| **AgentDojo** | 动态环境下 agent 受攻击与防御 | `ethz-spylab/agentdojo` 846★，v0.1.35 |
| **Agent-SafetyBench** | agent 安全（含工具误用） | `thu-coai/Agent-SafetyBench` 160★ |
| **ToolEmu** | 用 LM 模拟环境做**风险识别**（不用真实工具也能测危险行为） | `ryoungj/ToolEmu` 223★（2024-03，较早） |
| **HAL（Holistic Agent Leaderboard）** | 端到端 agent 评测，**统一跑 harness + 成本统计** | `princeton-pli/hal-harness` 311★ |
| **Terminal-Bench / WebArena / AgentBench** | 终端、Web、通用 agent 能力 | 传统基准，适合能力回归 |
| **LLM-AggreFact / RAGTruth** | 接地/忠实度 | 见 §5.2 |
| **越狱与注入** | garak、PyRIT、promptfoo redteam、Tencent AI-Infra-Guard | 见 §7.4 |

> **用法**：把"公开基准子集 + 自建业务集 + 线上捞回的难例"三者合成**公司自己的金标集**，公开基准只用来做能力基线和对外沟通。

---

## 6. 钩子与中间件：跨框架对照（附"阻断语义"的坑）

### 6.1 主流框架的注入点（2026-09 实测版本）

| 框架 | 注入形态 | 覆盖控制点 | 能否阻断 | 实测状态 |
| --- | --- | --- | --- | --- |
| **LangChain（v1 Middleware）** | **node-style**：`before_agent` / `before_model` / `after_model` / `after_agent`；**wrap-style**：`wrap_model_call` / `wrap_tool_call` | C2–C6、C12 | ✅（可 `can_jump_to=["end"]` 提前结束） | 146.7k★；内置 PII 检测、工具重试、模型回退、调用次数限制、`HumanInTheLoopMiddleware` |
| **LangGraph** | 图节点 + **Interrupts**（持久化中断/恢复） | C6、C13 | ✅ | 42.0k★；可把带 middleware 的 agent 作为子图嵌进更大的 StateGraph |
| **OpenAI Agents SDK** | `input_guardrails` / `output_guardrails` / **tool guardrails**（每次被守护的函数工具调用都跑：执行前 + 执行后）+ **tripwire**；`needs_approval` 审批 | C1、C5、C6、C12 | ✅（抛异常终止） | 29.6k★ v0.22.3 |
| **Google ADK** | **6 个 callbacks**：`before_agent` / `after_agent` / `before_model` / `after_model` / `before_tool` / `after_tool` | C2–C6、C12 | ✅ 且**可"伪造结果"** | 21.6k★ v2.9.2 |
| **Semantic Kernel** | **3 类 Filters**：Function Invocation / Prompt Render / **Auto Function Invocation**，pipeline + `next` 委托 | C3–C6 | ✅（不调用 `next` 即不执行） | 28.6k★（dotnet-1.80.1） |
| **Microsoft Agent Framework** | agent / run 级 middleware | C2–C6 | ✅ | 13.6k★（dotnet-1.22.0） |
| **Strands Agents** | 事件式 hooks（工具调用前后等） | C6 | ✅ | 7.4k★ |
| **CrewAI** | Task guardrails（含 LLM guardrail）、Flow | C4、C12 | ✅ | 58.8k★ v1.15.22 |
| **Claude Agent SDK** | **Hooks**（宿主应用在 agent loop 特定点调用的 Python 函数）+ 权限模式（`acceptEdits` 等）+ 自定义工具 | C1、C5、C6、C12 | ✅（`permissionDecision: deny`） | SDK README 实测；注意 `allowed_tools` **只控权限不控可用性**（易误解） |
| **Claude Code（CLI）** | **钩子事件**（按文档出现频次排序）：`PreToolUse`(74) · `PostToolUse`(69) · `SessionStart`(44) · **`PermissionRequest`**(25) · `UserPromptSubmit`(23) · `SubagentStop`(22) · `StopFailure`(17) · `Notification`(16) · `SessionEnd`(14) · `TaskCompleted`(14) · `TeammateIdle`(14) · `PreCompact`(11) | C1–C13（最全） | ✅（含**代用户授权/拒绝**） | 147k★；`UserPromptSubmit` 默认 30s 超时且**阻塞模型处理**，注意延迟 |
| **网关层** | agentgateway（LLM + MCP + A2A + 护栏 + CEL RBAC）、Bifrost、LiteLLM、Higress、Kong | C1、C5、C6 | ✅ | agentgateway 4.9k★ v1.5.0；Bifrost 8.2k★ |

### 6.2 三个必须知道的"阻断语义"细节

1. **并行护栏 ≠ 先拦后放**（OpenAI Agents SDK）：输入护栏有两种模式——`run_in_parallel=True`（默认，护栏与 agent 并发跑，触发 tripwire 时 *"the agent may have already consumed tokens and executed tools before being cancelled"*）与 `run_in_parallel=False`（**阻塞式**，护栏跑完 agent 才启动）。**要防副作用必须显式选 blocking。**
2. **钩子可以"伪造工具结果"**（Google ADK）：`before_tool_callback` 返回一个 dict，**真实工具函数被跳过**，该 dict 作为工具调用结果回给模型——非常适合做**干跑/影子/缓存/策略替代**，同时也意味着**钩子本身就是权限面**（谁能写钩子谁就能改 agent 行为）。
3. **钩子超时会变成新的故障点**（Claude Code）：`UserPromptSubmit` 在 command/http/mcp_tool 类型下默认 **30 秒**超时（大多数其他事件默认 600 秒），因为它要**阻塞**每一次提示。**凡是同步阻塞型钩子，都必须显式定义超时与超时后的行为。**

### 6.3 三种注入位置的权衡

| 位置 | 优点 | 缺点 | 适合 |
| --- | --- | --- | --- |
| **进程内（SDK/中间件）** | 能看到完整上下文与推理链；可改写、可伪造结果；延迟最低 | 与框架强耦合，每个框架都要适配 | 业务侧自研 agent 的**主力拦截点** |
| **网关（LLM/MCP 网关）** | 跨部门统一；配额/预算/凭据托管/模型路由；不可绕过 | 看不到 agent 内部状态（只有请求/响应），难做意图级判断 | 平台的**强制收口层**（禁止业务侧直连模型/工具） |
| **运行时外壳（sandbox / hypervisor）** | 兜底一切（文件、命令、网络、凭据）；对 agent 无侵入 | 粒度粗；不解决"调错无害 API" | 代码执行 / computer use / 终端 agent 的**最后防线** |

> **推荐组合**：网关做强制收口 + 进程内中间件做语义拦截 + 沙箱做兜底 + 运行期在线评测做验证。四者都不可省。

### 6.4 平台团队应强制的"最小钩子契约"（6 条）

对齐 ACS/AGT 的实践，要求所有上 T1/T2 的 agent 平台至少暴露并**强制经过**下列钩子：

1. `input_pre` —— 输入进入，可拒绝/改写/脱敏
2. `plan_post` —— 计划生成后、执行前校验
3. `tool_pre` —— 工具执行前，可拒绝/改参数/**伪造结果**（干跑）
4. `tool_post` —— 工具结果**入上下文之前**，可审查/脱敏
5. `output_pre` —— 对外输出前，可拒绝/改写
6. `session_end` —— 结算、审计封存、指标上报

并强制两条**元数据**：每个工具声明**风险等级**与**干跑能力**；每条拦截事件写 **OTel trace + `gen_ai.evaluation.result` 事件**（与公司埋点规范 v0.1 对齐）。

---
## 7. 运行期在线验证：三种形态（"定期在线测试集验证"的完整落地）

### 7.1 先分清三件事

| 形态 | 触发方式 | 数据来源 | 能发现什么 | 成本 | 典型工具 |
| --- | --- | --- | --- | --- | --- |
| **A. 采样在线评测** | 每条/抽样 trace 实时 | **真实用户流量** | 质量下降、幻觉上升、失败模式变化 | 中（按采样率） | LangSmith / Langfuse / Weave Signals / Datadog / Opik / Braintrust |
| **B. 定期金标集回放** | 定时（分钟/小时/天）或事件触发 | **固定测试集**（人造） | 功能回归、工具/网关/凭据/配额层故障、**跨版本对比** | 低（可控） | promptfoo / deepeval / 观测平台 datasets / 自建 scheduler |
| **C. 对抗探针** | 发布前必跑 + 每月定跑 | **攻击样本** | 注入、越权、越狱、数据外泄 | 中 | AI-Infra-Guard / garak / PyRIT / promptfoo redteam / AgentDojo |

**三者互补关系**：A 告诉你"线上正在发生什么"（真实但难定位），B 告诉你"确定的功能还对不对"（可比但对新问题不敏感），C 告诉你"有没有人/有没有输入能攻破它"（对抗性）。**只有 A 会漏掉回归，只有 B 会漏掉线上新问题，只有 C 会漏掉真实业务分布。**

### 7.2 形态 A：采样在线评测（已商品化，实测能力清单）

| 平台 | 关键能力 | 实测状态 |
| --- | --- | --- |
| **LangSmith** | **Online Evaluators**：可对"触发条件"过滤（**按工具调用**、按 metadata、按用户反馈）+ **采样率**（如 0.1 = 10%）+ **周花费上限**（超限自动暂停评测）+ **历史回填**（只可在创建规则时设定）+ **多轮对话级**在线评测；被评测的 trace 会自动升级为 extended data retention（**会影响计费**） | 官方文档已取证；SDK `langchain-ai/langsmith-sdk` 1.1k★ |
| **Langfuse** | LLM-as-a-judge 评测器 + 监控；可自托管（数据不出域） | `langfuse/langfuse` **35k★，v4.38.0** |
| **W&B Weave — Signals** | *"Every incoming production trace is automatically processed and scored"*：面向 agent 的**自动化行为打分**（官方点名幻觉、对话模式、接地丢失）；算力由 CoreWeave GPU 承载以支撑百万级 trace | 文档已取证（注：W&B 域名 2026-09-30 变更） |
| **Opik（Comet）** | 追踪 + 自动化评测 + 生产监控 | `comet-ml/opik` 22.2k★，v2.2.71 |
| **Arize Phoenix** | 开源评测/观测，支持在线评测流程 | `Arize-ai/phoenix` 11.6k★，arize-phoenix-v20.14.0 |
| **Datadog LLM Observability** | 托管评测（企业已有 Datadog 时最省事） | 官方文档存在但为前端渲染，**未完整取证**，需自行核对当前能力 |
| **Laminar / TruLens / Evidently / Braintrust / future-agi** | 规则扫 trace / feedback function / 漂移监控 / 评测平台 | lmnr 3.3k★ v0.2.5；trulens 3.6k★（trulens-2.14.0）；evidently 7.9k★；braintrust-sdk 27★（npm 为主）；future-agi 2.0k★ |
| **FailproofAI** | 面向 **12 种 agent harness** 的 hooks + 策略执行 + 审计（*"we see it — and we can say no"*） | 4.7k★；**注意许可证为 "MIT + Commons Clause"（非纯 OSI 开源）** |

**落地建议**：
- 选**已私有化/已采购**的那一个，不要引入第二套观测平台。
- 评测结果务必**写回 trace 事件**（`gen_ai.evaluation.result`），否则质量数据与运行数据割裂。
- 先定 **3–5 个评测器**（不要 20 个）：任务成功、工具正确性、接地性、政策合规、成本/步数异常。

### 7.3 形态 B：定期金标集回放（最重要、最容易被忽略的一环）

**定义**：用**与生产完全相同的部署**（同网关、同策略、同凭据体系、同记忆后端），按固定节奏跑一个**版本化的固定测试集**，断言行为是否符合预期。

**设计要求（可直接抄）**：

1. **触发节奏**：每 15 分钟（核心 T2）/ 每小时（T1）/ 每天（T0）；**外加事件触发**——每次发布、模型切换、策略包更新、工具版本变更后必须跑一次。
2. **数据集**（建议 30–300 条，版本化、评审、不可随手改）：
   - 正常路径（happy path）40%
   - 边界与畸形输入 20%
   - **应当被拒绝**的样本（越权、超范围、注入）20%
   - 多轮 + 上下文压缩 10%
   - 工具失败/超时/脏数据 10%
3. **隔离与安全**：专用测试租户 + 只读凭据；写类工具**强制 dry_run**；生产数据脱敏；**禁止**对真实客户产生副作用。
4. **断言方式**：结果断言（最终答复关键字段）+ **轨迹断言**（工具调用序列、参数、是否命中拦截）+ 非功能断言（p95 延迟、步数、单任务成本）。
5. **与基线对比**：与"最近一次通过的版本"逐条 diff，输出**新增失败**清单（不是只看总通过率）。
6. **闭环**：超阈自动动作——告警 → 降采样/切只读 → 自动回滚 → 冻结该 agent 的自动发布（与 §7.6 对齐）。
7. **顺带验证幂等性**：重复跑同一批写类用例，用幂等键断言**不产生重复副作用**。
8. **保留原始 trace**，失败样例自动进入待标注队列，成为下一版金标集/回归集的来源。

> **价值定位**：这是"**运行期**验证"，与 CI 里的离线评测是两件事。离线评测发现不了"网关策略配错、MCP 版本漂移、凭据过期、配额被下调、记忆被污染"这类**环境层**问题——而它们正是生产事故的主要来源。

### 7.4 形态 C：对抗探针（红队常态化）

| 工具 | 能力 | 实测状态 |
| --- | --- | --- |
| **腾讯 AI-Infra-Guard（A.I.G）** | 全栈 AI 红队平台：**Agent Scan / Skill-Scan / MCP Server 扫描 / AI 基础设施漏洞 / LLM 越狱评测**（含多轮越狱攻击） | `Tencent/AI-Infra-Guard` **6.5k★，Apache-2.0，v4.6.1（2026-09-10）**；**默认无鉴权，定位为企业内部使用**，部署需自行加固 |
| **NVIDIA garak** | LLM 漏洞扫描器 | 9.3k★，v0.17.0 |
| **Microsoft PyRIT** | 官方红队框架（Azure 生态集成） | Microsoft 官方项目 |
| **promptfoo** | 声明式评测 + **redteam/pentest**，CLI/CI 友好 | 25.3k★，v0.123.1 |
| **AgentDojo / Agent-SafetyBench** | agent 攻击与防御的学术基准 | 见 §5.5 |
| **Anthropic Petri** | 用**自动化审计 agent** 做多轮探测并打分（已用于 Claude 4 system card） | 2025-10 开源 |

**建议频率**：发布前必跑（门禁）；每月全量；每次出现新的注入手法（行业新闻/内部情报）后加跑专项。

### 7.5 成本与采样率（工程估算，非实测）

| 分级 | 采样在线评测 | 定期回放 | 对抗探针 | 评测预算上限（占 agent 推理成本） |
| --- | --- | --- | --- | --- |
| **T0（内部/低风险）** | 1% | 每天 1 次 | 每季度 | ≤ 5% |
| **T1（有损/对外）** | 5–10% | 每小时 1 次 | 每月 | ≤ 10% |
| **T2（关键/有资金或合规影响）** | 20–100% | 每 15 分钟 | 发布前 + 每月 | ≤ 20% |

**四条省钱的工程原则**：
1. **能白盒不用黑盒**：token 概率类不确定性（UQLM 白盒 scorer）**零额外调用**，先用它筛，再用 judge 复核可疑样本。
2. **能小模型不用大模型**：审核/判官用小模型（Llama Guard 4、Qwen3Guard 0.6B–8B、Granite Guardian）。
3. **能异步不阻塞**：在线评测走旁路，只在"必须拦"的控制点用同步。
4. **能缓存不重复**：同一 trace 的多次评测结果缓存；评测器版本变更时才重算。

> 粗略估算式：`评测月成本 ≈ 流量(次/月) × 采样率 × 每次评测成本(判官调用 + 存储)`。以 T1 业务量 10 万次/月、采样 10%、每次 2 次小模型调用为例，量级在"数千次小模型调用/月"，相对主推理成本可控——但**必须是显式预算项**，否则会失控。

### 7.6 指标 → 阈值 → 自动动作（把监控变成控制）

| 指标 | 触发条件（示例） | 自动动作 |
| --- | --- | --- |
| `policy_violation_rate` | 5 分钟内 > 基线 3σ | 告警 + 采样率提到 100% + 通知 on-call |
| `tool_call_hallucination_rate` | > 1%（滚动 15 分钟） | 自动**降级为只读**（关闭写类工具） |
| `ungrounded_claim_rate` | > 阈值 | 强制开启"无来源不得断言" + 转人工复核 |
| `regression_pass_rate`（金标集） | < 基线 −2% | **冻结发布** + 打开 diff 报告 |
| `p95 latency` / `cost_per_task` | 超 SLO 20% | 熔断高成本工具 + 降级模型 |
| 对抗探针新失败 | 任一高危用例失败 | **阻断发布** + 升级安全评审 |

> 关键：**每个指标都必须绑定一个自动动作**。只有告警没有动作的监控，在事故复盘里等于没有。

---

## 8. 证据链：怎么把这些变成"领导能信"的东西

### 8.1 可靠性档案（Reliability Dossier）——建议每次发布自动生成

| 项 | 内容 | 来源 |
| --- | --- | --- |
| 版本与制品 | agent 版本 + prompt/model/tool/memory/policy/eval 六个制品版本 | manifest（见前置文档 §3.1） |
| 离线评测 | 回归集通过率、失败模式 diff、安全评测结果 | CI |
| 对抗评测 | 注入/越权用例通过率（**ASR：攻击成功率**） | 红队任务 |
| 在线验证 | 过去 24h/7d 的采样评测分数、金标集回放结果、漂移量 | 形态 A/B |
| 运行指标 | p95 延迟、单任务成本、工具错误率、`escalation_rate` | OTel |
| 控制状态 | 已启用的钩子、策略包版本、拦截命中 Top 10、误报率 | 拦截层 |
| 事故与回归 | 本版本相关 incident、上次事故的修复验证 | 事件系统 |
| 授权 | 当前自主度级别（ATF L1–L4）、升级证据、审批签字 | 流程系统 |

> 领导不需要看 dashboard，需要看**一页纸**：这版能不能上、上了之后我们用什么信号判断它在变坏、变坏时会发生什么。

### 8.2 决策级审计（能被审计/监管听懂）

- **每个被拦截的动作都要留**：谁（agent 身份）、何时、用什么权限、请求了什么、命中哪条策略、判定结果与**理由**、参数摘要。
- **防篡改**：append-only 日志 + **Merkle 审计链**（AGT ADR-0017 的范式）；**Decision BOM**（可重建的决策账单，ADR-0018）。
- **可回放**：给定 trace id，能重建"当时 agent 看到什么、做了什么决定、为什么"——事故复盘与合规取证都靠这个。
- **OTel 落地**：拦截事件写 span 属性 + `gen_ai.evaluation.result` 事件（与公司埋点规范 v0.1 对齐），并映射 **OCSF** 以接入现有 SIEM。

### 8.3 刹车能力（必须演练，不能只写在文档里）

- **Kill switch**：按 agent / 按工具 / 按租户三个粒度；**演练目标是秒级**（撤销身份比停服务更快）。
- **只读降级**：一键关闭全部写类工具，agent 仍可问答（业务不中断）。
- **凭据吊销**：agent 用独立 workload identity（不要共享服务账号），吊销即失效。
- **在途任务处理**：持久化执行框架（Temporal/Restate/DBOS/Hatchet）支持"暂停/取消/补偿"，否则刹车会留下半成品业务数据。
- **演练频率**：每季度一次"agent 事故演练"（含误拦截演练），记录 MTTR。

### 8.4 分级授权（把 ATF 直接变成流程）

| 级别 | 允许 | 允许前必须有的证据 | 降级触发 |
| --- | --- | --- | --- |
| **L1 只读** | 查询/检索/摘要 | 埋点齐全 + 基础评测通过 | — |
| **L2 建议** | 生成待人工确认的动作 | 上述 + 金标集回放 + 对抗评测通过 | 输出被频繁驳回 |
| **L3 在护栏内行动** | 低危写操作，事后通知 | 上述 + 在线评测窗口达标 + 拦截误报率 < 阈值 + 刹车演练通过 | 任一 SLO 击穿 |
| **L4 边界内自主** | 域内自主决策，边缘案例升级 | 上述 + 持续 N 周无 incident + 独立审计 | incident / 漂移超阈 |

> 这套分级的最大价值：**它把"要不要信任 agent"从技术争论变成了有证据、可撤销的过程**。

### 8.5 与合规的对接（对外可讲）

| 要求 | 我们提供什么 |
| --- | --- |
| EU AI Act（高风险管理体系：可证明的人工监督与干预） | 控制点清单 + 拦截/审批记录 + kill switch 演练报告 |
| NIST AI RMF（持续监控、可停用） | 在线评测 + 漂移检测 + 自动降级策略 |
| OWASP Agentic Top 10 (2026) | 逐条对照表（工具化程度最高的是 AGT 的 ASI 对照文档） |
| ISO/IEC 42001 | 可靠性档案 + 审计链 + 变更流程 |
| 国内算法/生成式 AI 备案与内容安全要求 | 审核模型（如 Qwen3Guard 私有化部署）+ 内容拦截记录 + 人工审核流程 |

---
## 9. 厂商与产品（2026-09 状态）

### 9.1 AWS

- **Bedrock Guardrails**：内容过滤器、主题策略、词过滤、PII、**Contextual grounding check**（grounding + relevance，带置信度与阈值；注意流式场景的判定时机与长度上限）、**Automated Reasoning checks**（形式化验证）。**这是目前唯一把"形式化验证"做成开箱能力的大厂服务。**
- **AgentCore**：Policy（**Cedar**，在网关拦截每一次工具调用）、Evaluations、Optimization（A/B 实验）、Observability、Registry、Memory、Identity（详见前置报告 §13.1）。
- **适用**：已在 AWS 生态、需要"合规级证据"的场景。

### 9.2 Microsoft Azure

- **AI Content Safety**：**Groundedness detection**（含**自动纠正**：把不接地的数值/名字改成来源中的值）、**Task Adherence（preview）**——后者是"监督 agent 查工具调用"最直接的商品化能力（含 reasoning 与阻断/升级信号）。
- **Foundry**：**Continuous evaluation（preview）**——按**采样率**对 agent 交互做近实时评测，指标进 Observability dashboard，**结果与 trace 关联**便于定位；前提是接入 Application Insights。（官方文档区分 classic / new portal，注意版本差异。）
- **AI Red Teaming Agent**：把 **ASR（Attack Success Rate）**形式化为指标（被 AGT 等第三方引用为标准做法）。
- **适用**：已在 Azure/Entra 体系、需要与现有合规流程复用的场景。

### 9.3 Google Cloud

- **Model Armor**：输入/输出筛查 + **清洗（sanitize）**，返回每个过滤器的命中/未命中详情；可跨云使用。文档明确"预防恶意输入、校验内容安全、保护敏感数据、保持合规"。
- **Vertex AI / Agent Engine**：agent 评测能力（Agent Engine evaluation）。
- **ADK**：6 个 callbacks（**其中最有用的是"可伪造工具结果"的 `before_tool_callback`**）+ 内置评测流程。
- **适用**：已在 GCP、需要托管式输入输出筛查的场景。

### 9.4 专用厂商与整合趋势

| 类别 | 代表 | 备注 |
| --- | --- | --- |
| 观测 + 在线评测 | **LangSmith**、**Langfuse**、**Arize（Phoenix/AX/Alyx）**、**Datadog**、**Braintrust**、**W&B Weave**、Laminar、Opik | 优先选修可私有化部署的（数据不外流） |
| 运行时控制/安全 | **FailproofAI**、**secureagentics/Adrian**（**AARM-aligned**，主张"动作 + 推理"双看，含 Claude Code 插件）、AGT（微软，开源）、Noma Security、Operant AI、Runlayer、Highflame（含 **kill switch + 即时撤销**）、Airia（统一 AI 网关内联拦截）、MintMCP、QuilrAI | AARM 官网列出的 compliant builders，可直接用于竞品对比 |
| 判官/事实核查 | **Patronus AI**（Lynx/Verify 系列）、Galileo **Luna-2** | 具体能力**建议以厂商最新文档核对**（本次未能取证其文档站点） |
| **已被并购/更名（重要）** | **Galileo → Splunk Agent Observability（2026-08-07 起）**，官方文档已切换域名 | ✅ 已从官方文档确认 |
| 并购（据公开报道，建议核对） | Prompt Security→SentinelOne、CalypsoAI→F5、Protect AI / HiddenLayer→Palo Alto Networks、Humanloop 团队→Anthropic | ⚠️ 未在本次调研中取证 |

> **选型结论**：**不要押注单点厂商**。把"控制点契约 + 指标定义 + 数据格式（OTel/OCSF）"留在自己手里，厂商只替换实现——这也是 ACS 存在的原因。

### 9.5 国内可用（私有化优先）

| 项目 | 能力 | 实测状态 |
| --- | --- | --- |
| **Qwen3Guard**（阿里） | 审核模型：Gen（整段）+ **Stream（token 级实时）**；0.6B/4B/8B；三档严重度；119 语言；配套 **Qwen3GuardTest** 评测集与 SafeRL 安全对齐模型 | `QwenLM/Qwen3Guard`（511★）；模型在 HF/ModelScope；**可完全私有化** |
| **腾讯 AI-Infra-Guard** | 红队平台：Agent Scan、Skill-Scan（含 .pyc 字节码绕过检测、字符集走私防御）、MCP Server 扫描、AI 基础设施漏洞扫描、多轮越狱评测 | `Tencent/AI-Infra-Guard` 6.5k★ Apache-2.0 v4.6.1 |
| 云厂商内容安全审核（阿里云/火山/百度/腾讯云等） | 文本/图片/音频审核、敏感词、越狱检测 | ⚠️ 各产品线名称与能力迭代快，**建议按当前官方文档逐项核对**（本次未取证） |

---

## 10. 选型矩阵（按场景直接查）

| 需求 | 首选 | 备选 | 备注 |
| --- | --- | --- | --- |
| 工具调用合法性（H1） | **自建 P1 契约校验** | AGT `govern()` | 零成本，先做这个 |
| 越权/边界策略 | **Cedar**（若用 AWS）或 **OPA/Rego** | CEL（网关侧）、AGT Policy Engine | 策略要版本化 + 单测 |
| 注入/有害内容 | **LlamaFirewall**（agent 场景）或 **Llama Guard 4** | Qwen3Guard（国内/流式）、NeMo Guardrails、Model Armor | 优先"能拦在工具执行前"的方案 |
| 接地/忠实度 | **Contextual grounding（AWS）/ Groundedness（Azure）** | MiniCheck、HHEM、RefChecker | 流式场景注意判定时机 |
| 事实性关键断言 | **Automated Reasoning checks** | 领域判官 + 人工抽检 | 只覆盖关键断言 |
| 工具调用与意图一致性 | **Azure Task Adherence** | 自研 judge（Granite Guardian BYOC 判据） | 语义问题，需采样 |
| 不确定性/低置信度转人 | **UQLM 白盒 scorer** | 黑盒一致性、ensemble | 几乎零成本 |
| 运行时拦截中台 | **网关（agentgateway/LiteLLM/Higress）+ 进程内中间件** | AGT（试点）、FailproofAI | 网关收口不可省 |
| 在线评测 | **LangSmith / Langfuse（可私有化）** | Weave Signals、Datadog、Opik、Phoenix | 先定 3–5 个评测器 |
| 定期金标集回放 | **自建 scheduler + promptfoo/deepeval + 观测平台数据集** | 观测平台 experiments | **必须做**，见 §7.3 |
| 对抗探针 | **腾讯 AI-Infra-Guard / promptfoo redteam** | garak、PyRIT、Petri | 发布门禁 + 月度 |
| 人在环 | **LangGraph Interrupts / Agents SDK approvals** | Claude Code PermissionRequest、Temporal | 高危默认 fail-closed |
| 审计与证据 | **OTel + Merkle 审计链 + Decision BOM** | append-only 日志 + OCSF 导出 | 与埋点规范 v0.1 对齐 |
| 沙箱兜底 | **agent-sandbox / E2B / microVM** | Arrakis、gVisor/Firecracker | 代码执行类必备 |

---

## 11. 落地路线图（对齐前置报告的 L0–L9）

### 阶段 1：0–30 天 —— 先"看得见 + 拦得住"（成本最低，收益最大）
- [ ] 定义并下发 **§3.3 单一咽喉点契约** 与 **§6.4 最小钩子契约**（一页纸）。
- [ ] 所有 agent 工具做**风险分级**（只读/写/高危）+ 补 **幂等键** 与 **dry_run**。
- [ ] 上 **P1 契约校验**（白名单 + Schema + 参数范围）——目标：工具调用幻觉显著下降。
- [ ] 观测：拦截事件 + 评测结果写入 OTel（复用已有埋点规范，不新建 schema）。
- [ ] 定义 **5 个指标**（§5.3）+ 一页纸可靠性档案模板（§8.1）。

### 阶段 2：30–90 天 —— 建立"在线验证"闭环
- [ ] 搭 **金标集回放**（§7.3）：30–50 条起，cron + 发布事件触发，写指标与 diff 报告。
- [ ] 开 **采样在线评测**（T1 5–10%），选 3–5 个评测器，设**周花费上限**。
- [ ] 接入 **P2 策略引擎**（先做高危工具的确定性拦截，fail-closed）。
- [ ] 接 **P3 一个分类器**（注入/有害）+ **一个接地检查**（RAG 类 agent 必配）。
- [ ] 对抗探针纳入**发布门禁**（至少 promptfoo redteam 子集）。
- [ ] **刹车演练**第一次（kill switch / 只读降级 / 凭据吊销）。

### 阶段 3：90–180 天 —— 分级授权 + 证据链
- [ ] 按 **ATF 四级**给每个 agent 定级，写清升级证据与降级触发（进 manifest）。
- [ ] 指标 → **自动动作**（§7.6）：至少实现"幻觉率超阈自动切只读""回归失败自动冻结发布"。
- [ ] **决策级审计**（Merkle/Decision BOM 范式）+ 与 SIEM 打通（OCSF）。
- [ ] 试点 **P5 形式化验证**（选 1–2 个 T2 场景的关键断言）。
- [ ] 关键 agent 上 **MCP 网关 + 沙箱**（工具联邦与代码执行收口）。
- [ ] 对外：整理 **OWASP ASI 对照表 + 可靠性档案**，形成可对外讲的合规材料。

---

## 12. 反模式清单（审查 agent 时逐条对照）

1. **用 prompt 当控制面**："你绝对不要删除数据库"——这不是控制。
2. **只有一个超级监督 agent**：延迟、成本、误报三输；监督者本身也会幻觉。
3. **把并行护栏当真拦截**（Agents SDK 默认并行）：以为拦住了，其实工具已经执行。
4. **监督失败时默认放行**：所有拦截层必须显式声明 fail-open/fail-closed，高危必须 closed。
5. **同步阻塞型钩子没有超时**：钩子一慢，业务全挂。
6. **没有 dry_run 就做影子流量**：影子流量产生真实副作用（重复下单、重复发邮件）。
7. **只测最终答复，不测轨迹**：agent 的错误多半在中间步骤。
8. **只有告警没有动作**：没有自动降级/回滚的监控等于装饰。
9. **用单一"幻觉分"考核**：H1–H5 混在一起，无法定位、无法修。
10. **评测集从不评审、随手改**：门禁失去可比性（应版本化 + 变更需评审）。
11. **不看误报率**：误报推高转人工率，业务侧最终会绕过管控——这是控制失效的头号原因。
12. **把监督预算当免费**：在线评测的成本必须显式预算化 + 设上限（LangSmith 的周花费上限就是这个思路）。
13. **共享服务账号 + 无独立身份**：出事无法归因，也无法"只吊销一个 agent"。
14. **没有决策级审计**：只能回答"agent 大概做了什么"，不能回答"为什么放行"。
15. **自主度一次性给满**：没有从只读 → 建议 → 行动 → 自主的升级过程，也没有降级机制。

---

## 13. 性能与预算约束（工程估算，供容量规划参考）

| 监督环节 | 典型附加延迟 | 备注 |
| --- | --- | --- |
| P1 契约校验 | < 1ms | 纯本地计算 |
| P2 策略引擎（本地） | 1–5ms | Cedar/OPA 本地评测 |
| 网关拦截（网络跳数） | 5–30ms | 取决于拓扑 |
| P3 小模型分类器（自托管 GPU） | 10–200ms | 批处理可摊销 |
| P3 托管内容审核 API | 50–300ms | 受网络与配额影响 |
| P4 LLM-judge（大模型） | 0.5–10s | **不建议放在同步关键路径** |
| P5 形式化验证 | 秒级 | 放离线/准在线 |
| 正则/词表/CodeShield | < 10ms | — |

**三条硬约束**：
1. **同步路径上只允许 P1/P2 + 极少量 P3**；P4/P5 一律异步或采样。
2. **每个拦截层必须有超时 + 失败语义 + 熔断**（AGT ADR-0013/0020）。
3. **总预算**：控制层附加延迟目标 **p95 < 100ms**；在线评测成本 ≤ agent 推理成本的 10–20%。

---

## 14. 参考与取证材料

| 路径 | 内容 |
| --- | --- |
| `research/vendor2/` | 厂商官方文档全文（ACS、AARM、ATF、AWS grounding/AR、Azure groundedness/task adherence/continuous evaluation/red team、Model Armor、LangSmith online evals、LangChain middleware、Langfuse judge、Claude Code hooks、Claude Agent SDK、ADK callbacks/eval、SK filters、LangGraph interrupts/durable、OpenAI Agents guardrails/HITL/tracing/MCP、Anthropic constitutional classifiers/Petri、OWASP ASI、galileo、datadog、weave、braintrust 等） |
| `research/pages4/` | 项目 README 原文（LlamaFirewall、Llama Guard 4、NeMo Guardrails、Guardrails AI、Qwen3Guard、Granite Guardian、MiniCheck、SelfCheckGPT、RefChecker、UQLM、τ²-bench、HAL、Agent-as-a-Judge、Agent-SafetyBench、ToolEmu、AgentDojo、terminal-bench、microsoft/agent-governance-toolkit、Tencent AI-Infra-Guard、Adrian、FailproofAI、nono、open-multi-agent、valqore、cc-safety-net 等） |
| `research/meta3.txt` / `meta4.txt` / `meta5.txt` | star / 最新 release / 最近提交 / 许可证 快照（2026-09-21） |
| `research/gh_scan_guard.txt` | 主题检索结果（含大量长尾项目，可据此跟踪生态） |
| `research/run_runtime_control.ps1` / `run_runtime_control2.ps1` / `run_fetch10/11/12.ps1` | 复现脚本 |

**复现方式**：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_runtime_control.ps1   # 文档 + README + 元数据 + 主题检索
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_runtime_control2.ps1  # 第二轮（修正 URL + 新项目）
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_fetch10.ps1          # 标准 / 框架文档
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_fetch11.ps1          # LangSmith / 中间件 / OWASP
powershell -NoProfile -ExecutionPolicy Bypass -File research/run_fetch12.ps1          # ACS / middleware hooks
```
**取证局限（如实说明）**：
- 部分厂商文档站点（docs.langchain.com 部分页面、arize.com、comet.com、braintrust.dev、patronus.ai、vijil.ai、genai.owasp.org 部分页面）在抓取时被拒绝或限流，相应结论已用镜像或官方 README 替代，**未能取证的项已在正文标注**。
- Datadog 文档为前端渲染，未完整取证。
- 本报告的 star/版本为 2026-09-21 快照，会随时间变化。
- 延迟/成本表格与采样率建议为**工程估算**，需按自身流量实测校准。

---

## 附录：给领导的 1 页速查

**一句话**：我们不承诺 agent 不犯错；我们承诺**错误落地前被拦住的比例**、**错误被发现的时间**、**每次决策可追溯**——并且随时可以降级为只读。

**三个可引用的标准**：
- **ACS（Agent Control Standard）**：行业在标准化"每个决策点的钩子 + 判定（allow/deny/modify）"。
- **AARM（CSA）**：运行时拦截的 6 条 MUST + 11 类威胁。
- **ATF（Agentic Trust Framework）**：自主权分四级，**挣来的、可撤销的**。

**四个可考核的指标**：`tool_call_hallucination_rate`、`policy_violation_rate`、`ungrounded_claim_rate`、`escalation_rate`。

**四层纵深**：契约校验（免费）→ 策略引擎（确定性）→ 分类器/判官（概率性）→ 人在环（兜底）+ 在线验证闭环。

**三件必须做的事**：① 所有工具调用过单一咽喉点；② 定期用生产版本回放金标集；③ 每个指标绑定一个自动动作。
