# 多业务部门自研 Agent 上生产：运维 / 进版 / 上线 全景调研

> 调研时间：2026-09-17　|　视角：**平台/技术支持团队**（为多个业务部门自研 agent 提供统一底座与上线支持）
> 数据来源：GitHub API 实时检索（star/最新 release/最近提交）+ 各项目 README + 官方文档（AWS / Azure / Google / OpenTelemetry）
> 原始取证材料见仓库内 `research/` 目录

---

## 0. 摘要：12 条核心判断

1. **Agent 不是微服务，需要一套新的"可发布制品"模型。** 一次 agent "进版"实际上同时改了 4~7 类制品：代码镜像、Prompt/指令包、模型与参数、工具/工具描述与 MCP server、记忆 schema、评测集、策略/护栏包。今天业界把这一整包称为 **agent revision / agent version**（Azure Foundry 的 agent version、LangSmith 的 revision、AgentCore 的 versioned configuration bundle）。
2. **可观测性已经标准化，不要再自造埋点。** OpenTelemetry GenAI 语义约定已迁到独立仓库 `open-telemetry/semantic-conventions-genai`，给出了 agent 级 span 模型：`create_agent` / `invoke_agent`(client,internal) / `invoke_workflow` / `plan` / `execute_tool`，加上 `inference` / `retrieval` / `memory` / `embeddings`；指标含 `gen_ai.invoke_agent.duration`、`gen_ai.invoke_agent.tool_calls`、`gen_ai.execute_tool.duration`、`gen_ai.client.token.usage`；事件含 **`gen_ai.evaluation.result`**（把评测结果作为运行期事件）与 `gen_ai.conversation.compacted`（上下文压缩可观测）。**先把这套 schema 定为公司内强制标准，再选平台。**
3. **发布门禁必须是"评测门禁"，而不是"单测门禁"。** 2026 年的标准做法是：变更 → 跑离线评测集（含多轮、工具、边界）→ 对比基线与失败模式聚类 → 人工评审 → 灰度。Google `agents-cli` 把这条流水线做成了 CLI：`eval run / eval grade / eval compare / eval analyze / eval optimize`。
4. **托管平台已经把"运维 + 上线"做成了商品化能力。** AWS Bedrock AgentCore 一口气给出 Runtime / Harness / Memory / Gateway / Identity / Policy(Cedar) / Observability / Evaluations / **Optimization(A-B 实验)** / **Registry(审批+语义检索)**；Azure Foundry 给出 Agent Runtime + Toolboxes + Observability + Optimizer + **Entra Agent Registry**；Google 给出 Agent Runtime + Agent Gateway + Sessions + Memory Bank(**memory revisions**) + Example Store + Feedback Service。**没自建能力的团队，2026 年已经没必要全自建。**
5. **网关是性价比最高的统一点。** 一个 AI/MCP 网关能同时解决：多模型路由与 fallback、配额与预算、密钥托管、内容护栏、MCP 工具联邦、工具级策略拦截、以及 prompt/tool 版本的 **A/B 流量切分**。代表项目：`agentgateway`(v1.5.0)、`envoyproxy/ai-gateway`(v1.1.0)、`LiteLLM`(v1.101.0)、`Higress`(CNCF Sandbox，国内生态最好)、`Kong AI Gateway`、`IBM ContextForge`(v1.0.10)。
6. **长事务要靠"持久化执行"（durable execution），不是靠重试。** Agent 任务动辄十几分钟到数小时、跨工具与人工审批，必须能崩溃续跑、幂等、可回放。成熟选项：`Temporal`、`Restate`、`Dapr Agents`(v1.0.5)、`Inngest`(v1.44.0)、`Hatchet`、`DBOS`；K8s 原生则是 `kagent`(v0.10.1) 与 **`kubernetes-sigs/agent-sandbox`(v1.0.2，SIG Apps 官方 Sandbox CRD)**。
7. **沙箱是硬需求，不是可选项。** 任何会执行代码/操作浏览器的 agent 都必须跑在隔离沙箱里（`kubernetes-sigs/agent-sandbox`、`E2B`、gVisor/Firecracker/microVM），对应托管能力是 AgentCore Code Interpreter / Browser、Vertex Code Execution、Foundry 的 hosted agent 容器。
8. **记忆（memory）是新的"状态库"，必须按数据治理来管，而不是当缓存。** 2026 年的标配是"记忆可版本化、可检视、可删除、可 TTL"（Vertex `Memory Bank` 提供 memory revisions；`mem0` 65k star、`Zep`、`Letta`、`LangMem`）。**发布回滚时最容易出事故的就是记忆 schema 与检索索引的不兼容。**
9. **安全重心已从"模型越狱"转向"工具与供应链"。** 排行靠前的风险是：工具/MCP server 投毒、prompt injection 借工具外泄、越权工具调用、MCP 供应链（`snyk/mcp-scan`）、以及"agent 自主支付/下单"。**AgentCore Policy（Cedar，拦截每一次工具调用）是这一层最好的范式参考**：策略在网关侧确定性执行，而不是写在 prompt 里。
10. **注册中心（Agent Registry）是平台团队的核心抓手。** AWS AgentCore Registry、Microsoft Entra Agent Registry、MCP Registry（官方，v1.8.1，API v0.1 冻结）都在做同一件事：**"发布-审核-批准-发现"**。对多业务部门的平台团队，这是把"谁上线了什么 agent、用了哪些工具、数据流向哪"变成可治理资产的唯一办法。
11. **成本治理要在网关和循环两端同时下手。** 网关侧：配额/预算/模型路由/语义缓存/Prompt Caching；运行时侧：步数上限、上下文压缩（`gen_ai.conversation.compacted`）、子 agent 预算传递、成本随 trace 归因到业务部门。
12. **平台团队的正确形态是"铺好的路 + 分级门禁"（paved path + tiering）。** 提供：模板脚手架、SDK 包、强制 OTel 埋点、统一网关、评测服务、发布流水线、注册中心；业务部门保留 agent 行为的所有权。**没有分级（T0 内部试用 / T1 生产有损 / T2 生产关键）就不可能既快又稳。**

---

## 1. 问题定义：为什么传统上线/运维流程不够用

### 1.1 Agent 与传统服务的本质差异

| 维度 | 传统微服务 | Agent |
| --- | --- | --- |
| 输出 | 确定性、可断言 | 非确定性，同一个输入多次输出不同 |
| 正确性 | 单测 + 契约测试即可判定 | 需要"评测集 + 评分器"，本身就是一门工程 |
| 执行时长 | 毫秒~秒 | 秒~小时（长事务、等待人工、跨系统） |
| 失败语义 | 异常/超时 | **静默错误**：跑通了但答案是错的、越权的、花了 10 倍钱 |
| 变更面 | 代码 + 配置 | 代码 + Prompt + 模型 + 工具定义 + 记忆 + 策略 + 评测集 |
| 依赖 | 内部服务 | 外部模型/工具/MCP server（不可控、会静默变更） |
| 回滚 | 回滚镜像即可 | 回滚镜像后**记忆/状态/在途任务可能不兼容** |
| 成本 | 相对稳定 | 单次调用方差极大，可能被单用户打爆 |

### 1.2 平台团队要回答的四个问题

1. **运维**：Agent 在生产里"是否健康、是否在做正确的事、花了多少钱"能否被回答？→ 可观测 + 评测 + 成本 + 事故响应
2. **进版**：一次变更包含哪些制品？如何版本化？→ 制品模型 + 仓库 + 评测门禁
3. **上线**：如何安全地把新版本放到真实流量上？→ 灰度/影子/A-B + 策略与护栏 + 回滚
4. **规模化支持**：多个部门、多套框架、多种技术栈，如何不变成救火队？→ 标准 + 网关 + 注册中心 + 脚手架 + 分级门禁

---

## 2. 总体架构：Agent 生产化能力的 10 层模型（L0–L9）

```
L9  事故响应 / On-call / 复盘        ← SLO、runbook、kill switch、trace 回放
L8  成本与容量治理                    ← 预算、路由、缓存、上下文压缩、步数上限
L7  安全 / 权限 / 合规                ← 工具级策略(Cedar)、沙箱、MCP 供应链、审计
L6  记忆与状态治理                    ← 版本化、TTL、可删除、迁移、隔离
L5  发布与进版                        ← agent revision、灰度/影子/A-B、回滚语义
L4  评测与质量门禁                    ← 离线集、LLM-judge、trace-eval、CI 门禁
L3  可观测性                          ← OTel GenAI semconv、trace、会话回放、成本归因
L2  网关与流量治理                    ← LLM/MCP/A2A 网关、配额、护栏、工具联邦
L1  运行时与执行底座                  ← durable execution、K8s 运行时、沙箱、身份
L0  标准与契约                        ← agent manifest、命名、AGENTS.md、MCP/A2A、埋点约定
```

> 经验法则：**L0 与 L3 必须先做**（否则后面全是返工）；**L2 是投入产出比最高的一层**；**L5 依赖 L4**，没有评测就没有可信的灰度判据。

---

## 3. L0 标准与契约：让多部门 agent 可被统一治理

### 3.1 Agent Manifest（自研的最小必要标准）

建议每个 agent 上线必须提交一份 `agent.yaml`，纳入注册中心：

```yaml
name: cs-refund-agent            # 全局唯一，含部门前缀
owner: 客服技术部
tier: T1                         # T0内部 / T1有损 / T2关键
purpose: 处理订单退款咨询与工单创建
runtime:
  framework: langgraph
  entrypoint: image://registry/agent/cs-refund:1.4.2
  sandbox: required              # 是否需要代码/浏览器沙箱
artifacts:                       # 一次发布绑定的全部制品
  prompt_bundle: prompts@2026.09.17-1
  model: { primary: gpt-5.2-mini, fallback: [claude-sonnet-4.8] }
  tools: [mcp://order-svc@1.2.0, mcp://crm@3.0.1]
  memory_schema: mem-v3
  policy_bundle: policy@2026.09.10
  eval_suite: evalset-refund-v7
slo:
  task_success_rate: ">=0.92"
  p95_latency_s: 45
  cost_per_task_usd: "<=0.08"
  escalation_rate: "<=0.15"
observability:
  otel_genai: true               # 强制
  trace_sample_rate: 0.2         # 关键 agent 1.0
data:
  pii: true
  retention_days: 30
  region: cn-north
```

**要点**：把"制品清单 + SLO + 数据等级"写进 manifest，是后续所有自动化（门禁、灰度判据、成本归因、审计）的输入。

### 3.2 命名与埋点契约

- 强制 `gen_ai.agent.id` / `gen_ai.agent.name` / `gen_ai.agent.version` 三件套（OTel 已标准化），**agent.version 与发布版本联动**。
- 强制 `gen_ai.conversation.id` 贯通多轮；跨 agent 调用用 `invoke_agent` span 的父子关系表达，不要把多 agent 展平。
- 所有工具调用统一 `execute_tool` span，工具名 = `mcp://<server>@<version>#<tool>`，把版本写进名字，事故时能立刻定位是哪个版本的工具。
- 统一 `user.id` / `tenant.id` / `cost.center` 属性，用于配额与账单归因。

### 3.3 协议层（工具与 agent 互操作）

- **MCP**：事实标准。规范版本节奏快（最新发布日 2026-07-28），**必须固定并声明 server 支持的 MCP 版本**；官方 Registry 已进入 v0.1 API 冻结、正在推 GA（注册中心项目 v1.8.1）。
- **A2A**：agent 间协作协议，已到 **v1.0.1**（26k star，Apache-2.0，Linux Foundation 治理），跨部门/跨系统 agent 互调应选它，而不是自造 RPC。
- **AGENTS.md**：仓库级 agent 指令约定，已被大量工具链（含 OpenTelemetry 规范仓库本身）采用，用它统一"agent 开发规范"的下发。

### 3.4 团队协作契约

- 业务部门：拥有 agent 行为与 SLO，负责评测集与 runbook。
- 平台团队：拥有运行时、网关、可观测、评测服务、注册中心、发布流水线。
- 用 **RACI + 分级门禁** 固化，避免"上线后全找平台"。

---
## 4. L1 运行时与执行底座：让 agent 能"活着跑完"

### 4.1 核心方法

| 需求 | 做法 | 为什么 |
| --- | --- | --- |
| 任务跑完不丢 | **持久化执行**（工作流状态落盘 + 事件重放） | agent 循环中任何一步崩溃都能续跑，不必从零重来烧 token |
| 多 agent 协作不失控 | 子 agent 作为**工作流步骤**而不是嵌套函数 | 可观测、可限流、可取消、可预算传递 |
| 代码/浏览器操作 | **隔离沙箱**（microVM/gVisor/独立 Pod） | 防提示注入导致的宿主机逃逸与数据外泄 |
| 会话隔离 | 每会话独立沙箱/命名空间，带文件系统与 shell 能力 | AgentCore Harness 就是"每 session 一个 microVM" |
| 长任务与异步 | 异步任务 API + 回调/轮询 + 僵尸任务回收 | 生产上是"提交任务→查状态"，不是同步 HTTP |
| 身份 | Agent 有自己的 workload identity（不是共用 API Key） | 工具侧鉴权与审计的前提 |

### 4.2 项目清单（2026-09 实测 star / 最新版本）

**持久化执行 / 工作流**
- `temporalio/temporal`：最成熟的企业级持久化执行引擎，适合已有 Temporal 基建的团队。
- `restatedev/restate`：轻量、单二进制，Durable Execution 语义清晰，适合新起。
- `dapr/dapr-agents`（v1.0.5）：基于 Dapr Workflow/Actors，**单核可跑上千 agent、scale-to-zero**，K8s 原生，平台团队友好。
- `inngest/inngest`（v1.44.0）：事件驱动 + 持久步骤，前端/TS 团队上手快。
- `hatchet-dev/hatchet`、`dbos-inc/dbos-transact-py`：更轻量的替代。

**K8s 原生 agent 运行时（平台团队首选方向）**
- **`kubernetes-sigs/agent-sandbox`（v1.0.2）**：Kubernetes SIG Apps 官方的 `Sandbox` CRD + controller，专门解决"长生命周期、有状态、单例"工作负载（官方原话就是 "AI agent runtimes and reinforcement learning"）。**这是 2026 年最值得平台团队投入的项目之一**：把沙箱生命周期、暂停/恢复、状态保留交给 K8s 声明式管理。
- `kagent-dev/kagent`（v0.10.1）：K8s 原生 agent 运行时 + 治理（CNCF 生态）。
- `e2b-dev/E2B`（14k star）：托管式代码沙箱，接入快，适合先跑通再自建。
- 底层隔离：gVisor / Firecracker microVM / Kata Containers（自建沙箱时选型）。

**框架层（业务部门自选，但平台要约束"可埋点、可持久化、可沙箱化"）**
- Python 系：`langchain-ai/langgraph`（v0.4.x SDK，42k star，图式状态机，天然契合持久化）、`openai/openai-agents-python`、`google/adk-python`（v2.9.1）、`strands-agents/sdk-python`（AWS）、`pydantic/pydantic-ai`（v2.44.0，20k star）、`crewAIInc/crewAI`（v1.15.22）、`agno-agi/agno`（v3.0.10）、`microsoft/agent-framework`（v1.21.0 跨语言）、`microsoft/semantic-kernel`、`deepset-ai/haystack`。
- Java 系（国内企业大量存量）：`spring-projects/spring-ai`（v2.0.1，9.5k star）——**如果业务部门是 Java 栈，这是唯一现实的路径**。
- TS 系：`VoltAgent/voltagent`（10.6k，"AI Agent Engineering Platform"）、`openai/openai-agents-js`。
- 低代码/可视化平台（业务部门自助搭建常用，平台必须纳入治理：埋点、密钥、发布）：`langgenius/dify`（156k star，v1.17.1）、`coze-dev/coze-loop`（v1.5.1）、`infiniflow/ragflow`（RAG 知识库）。**治理要点**：这类平台的 agent 也必须走统一网关与统一埋点，否则会成为观测盲区。
- 工具层：`googleapis/genai-toolbox`（v1.11.0，17k star）——MCP Toolbox for Databases，把数据库安全地暴露成工具，**强烈建议平台统一提供**，避免各部门各写一遍 SQL 工具并各自管凭据。

### 4.3 落地要点

- **平台提供"黄金路径模板"**：一个包含 OTel 埋点、健康检查、任务 API、沙箱配置、Dockerfile、CI/CD、Terraform/Bicep 的模板仓库。Google `agent-starter-pack` → 已迁移到 **`google/agents-cli`**（`uvx google-agents-cli setup`，提供 `create/eval/deploy/publish` 与 staging/prod 的 `infra cicd`），是目前最好的"脚手架 + 生命周期 CLI"参考实现；直接借鉴其骨架即可。
- 不要强行统一框架：**统一"运行时契约 + 埋点契约 + 发布契约"**，框架自由。

---

## 5. L2 网关与流量治理：投入产出比最高的一层

### 5.1 一个网关能解决 7 件事

1. **多模型路由与 fallback**：主模型故障/限流自动切换，跨供应商（含国产模型）统一 OpenAI 兼容接口。
2. **配额与预算**：按部门/agent/用户/会话限流，硬性止损（这是"agent 把账单跑爆"的唯一可靠防线）。
3. **密钥托管**：业务部门不持有任何模型 Key，只拿网关的虚拟 Key。
4. **护栏**：输入/输出内容过滤、PII 脱敏、越权请求拦截。
5. **MCP 工具联邦与治理**：把内网 API/数据库/已有 MCP server 统一暴露成受控工具端点，集中鉴权。
6. **工具级策略拦截**：**每一次工具调用执行前做确定性策略判定**（谁能调、调什么、什么条件下），而不是把限制写进 prompt。
7. **实验与灰度**：在网关做 prompt/工具描述/模型版本的 A/B 流量切分（AgentCore Optimization 就是这么做的）。

### 5.2 项目清单

| 项目 | 版本/规模 | 定位与适用场景 |
| --- | --- | --- |
| **`agentgateway/agentgateway`** | v1.5.0，4.9k star | **最贴合本主题**：LLM Gateway + MCP Gateway + A2A Gateway + 推理路由 + 护栏 + CEL 细粒度 RBAC + OTel。基于 MCP/A2A 原生协议，Apache-2.0 |
| **`alibaba/higress`** | v2.2.4，9.4k star，CNCF Sandbox | 国内首选：基于 Istio/Envoy，Wasm 插件扩展，AI Proxy 支持国内外主流模型，**支持把 OpenAPI 一键转成 MCP server 并托管**，中文文档与生态完备 |
| **`BerriAI/litellm`** | v1.101.0，59k star | 事实标准的 LLM 代理/SDK，100+ 供应商，预算/限流/日志/虚拟 Key，接入成本最低；治理能力弱于专用网关 |
| **`envoyproxy/ai-gateway`** | v1.1.0，2.1k star | Envoy Gateway 体系，适合已有 Envoy/Istio 标准化的团队 |
| **`Portkey-AI/gateway`** | v1.15.2，13k star，MIT | 生产级 AI 网关，护栏/缓存/回退/可观测齐全，开源核心 + 商业版 |
| **`Kong/kong`**（AI Gateway 插件） | 3.9.x，44k star | 已有 Kong 的企业直接用，无需新增组件 |
| **`apache/apisix`** | v3.18.0，17k star | 国内使用广，AI 插件与 MCP 支持在补齐 |
| **`IBM/mcp-context-forge`** | v1.0.10，4.5k star | **MCP 注册中心 + 代理**：联邦 MCP/A2A/REST/gRPC，集中治理与 OTel 追踪，40+ 插件。想做"工具目录"时优先评估 |
| `tensorzero/tensorzero` | 18k star | Rust 网关 + 可观测 + 优化闭环，p99 开销 <1ms，适合高 QPS |
| `vllm-project/semantic-router` | — | 自建推理时的智能路由（按语义/复杂度选模型，省钱） |

### 5.3 建议的网关拓扑

```
业务 Agent (各部门, 任意框架)
        │  (OpenAI 兼容 / MCP / A2A)
        ▼
[ Agent Data/Gov Plane 网关 ]  ← 虚拟Key、配额、预算、护栏、策略(CEL/Cedar)、A/B、OTel
        │
   ┌────┼─────────────┬───────────────┐
   ▼    ▼             ▼               ▼
模型供应商  内网 MCP 工具   企业 API/Lambda   自建推理(vLLM/SGLang)
```

**关键约束**：所有 agent 出网只允许经过网关；**禁止业务直连模型 Key**——这一条能同时解决成本、安全、审计、灰度四个问题。

---

## 6. L3 可观测性：从"看日志"到"看轨迹 + 看质量"

### 6.1 标准：OpenTelemetry GenAI 语义约定（已迁至独立仓库）

**Span 模型**（`open-telemetry/semantic-conventions-genai`）：

| Span | 含义 | 运维用途 |
| --- | --- | --- |
| `create_agent` | 创建 agent 实例 | 启动/配置问题定位 |
| `invoke_agent`（client / internal） | agent 被调用（区分跨进程/内部） | 多 agent 拓扑、跨部门调用链 |
| `invoke_workflow` | 工作流编排 | 长事务耗时拆解 |
| `plan` | 规划步骤 | 判断"想错了"还是"做错了" |
| `execute_tool` | 单次工具调用 | 工具错误率、越权、超时 |
| `inference` / `retrieval` / `memory` / `embeddings` | 模型调用 / 检索 / 记忆读写 / 向量化 | 成本归因、检索质量 |

**关键指标**：`gen_ai.client.token.usage`、`gen_ai.client.operation.duration`、`gen_ai.client.operation.time_to_first_chunk`、`gen_ai.client.operation.time_per_output_chunk`、`gen_ai.server.*`、`gen_ai.invoke_workflow.duration`、`gen_ai.invoke_agent.duration`、**`gen_ai.invoke_agent.inference_calls`**、**`gen_ai.invoke_agent.tool_calls`**、`gen_ai.execute_tool.duration`。
> `inference_calls` / `tool_calls` 这两个指标非常实用：**"agent 绕圈"（loop）会表现为 tool_calls 异常升高**，是最早可发现的故障信号之一。

**MCP 指标**：`mcp.client.operation.duration`、`mcp.server.operation.duration`、`mcp.client.session.duration`、`mcp.server.session.duration`。

**事件**：`gen_ai.evaluation.result`（把评测结果写入 trace，实现"运行期在线评测"）、`gen_ai.client.inference.operation.details`、`gen_ai.conversation.compacted`（上下文压缩事件）。

**属性**：`gen_ai.agent.id / name / description / version`、`gen_ai.conversation.id`、`gen_ai.operation.name`、`gen_ai.provider.name`、`gen_ai.request.model`、`error.type`。

### 6.2 平台选型（按团队情况三选一）

| 方案 | 适用 | 说明 |
| --- | --- | --- |
| **`langfuse/langfuse`** v4.37.0（35k star） | 默认推荐 | 开源可自托管，trace + 评测 + Prompt 管理 + 数据集 + Playground 一体；v4 明确以"agent evals & observability"为定位 |
| **`mlflow/mlflow`** v3.16.1（28k star） | 已有 ML 平台 | MLflow 3 已转型为"AI engineering platform for agents/LLMs"，tracing + eval + 模型注册一体，**适合与既有 MLOps 体系合并** |
| **`comet-ml/opik`** v2.2.67（22k star, Apache-2.0） | 需要全功能自托管 | 可观测 + 评测 + Prompt 管理 + 生产监控 |
| `Arize-ai/phoenix`（v20.x） | OTel 原生派 | 纯 OTel/OpenInference 路线，评测与实验强 |
| `traceloop/openllmetry`、`openlit/openlit`、`Arize-ai/openinference` | 埋点层 | 负责把各框架的调用转成 OTel GenAI 标准，**可与上面任意后端组合** |
| `AgentOps-AI/agentops`（v0.4.21，5.8k）、`truera/trulens`（trulens-2.14.0，3.6k）、`coze-dev/coze-loop`（v1.5.1，5.7k，Apache-2.0） | 备选 | Coze Loop 是字节开源的中文 AgentOps 平台（Prompt 开发/评测/观测全生命周期），**国内落地阻力最小** |
| 商业全托管 | 无自建意愿 | LangSmith、Braintrust、Galileo、W&B Weave、Datadog LLM Obs、阿里云百炼/火山方舟自带观测 |

### 6.3 必须建的 4 个视图

1. **业务视图**：任务成功率、升级人工率、用户负反馈率（按 agent/版本/租户）。
2. **质量视图**：在线评测分数分布、`gen_ai.evaluation.result` 事件趋势、失败模式聚类。
3. **性能视图**：p95 端到端、每步耗时、首 token 延迟、inference_calls/tool_calls 分布。
4. **成本视图**：token 与金额按 `cost.center`/部门/会话归因，含"异常成本会话 Top N"。

---
## 7. L4 评测与质量门禁：进版的唯一可信判据

### 7.1 评测栈的四层结构

```
① 数据集层  : 回归集(固定) + 难例集(线上捞) + 合成多轮场景 + 对抗集   ← 线上采集链路见 7.4
② 评分器层  : 断言/规则 → 参照对比 → LLM-as-Judge(带 rubric) → 人工抽检
③ 执行层    : 离线批量跑 · Trace 级评测(对生产 trace 重打分) · 在线采样评测
④ 门禁层    : CI 阻断 / PR 评论 / 发布卡点 / 灰度放量判据
```

**2026 年的关键演进**：评测对象从"模型的最终答复"变为 **"trace"**。因为 agent 的错误往往在中间步骤（选错工具、参数错、检索到脏数据、多轮后忘记约束）。所以评分器要能挂在 `execute_tool` / `plan` / `retrieval` 这些 span 上——这也是 OTel 定义 `gen_ai.evaluation.result` 事件的原因。

### 7.2 项目清单

| 项目 | 版本/规模 | 定位 |
| --- | --- | --- |
| **`confident-ai/deepeval`** | python-v4.2.0，18k star | pytest 风格的 LLM 测试框架，最易嵌入 CI，指标丰富（含 agentic 指标） |
| **`promptfoo/promptfoo`** | v0.123.0，25k star，MIT | prompt/模型/agent 的声明式评测 + 红队，CLI + CI 友好，**跨部门推广成本最低** |
| **`langfuse` / `mlflow` / `opik` 自带评测** | 见 L3 | 已选观测平台则不引入第二套 |
| `UKGovernmentBEIS/inspect_ai` | 2.8k | 英国 AISI 官方评测框架，严谨、可复现，适合高危场景 |
| `EleutherAI/lm-evaluation-harness` | v0.4.13，14k | 模型能力基线（选型阶段用） |
| `vibrantlabsai/ragas`（原 `explodinggradients/ragas`） | v0.4.3，16k | RAG 检索/忠实度指标；**上游已迁移组织且最近提交停留在 2026-02，活跃度明显下降**，新项目建议评估替代方案 |
| `benchflow-ai/awesome-evals` | 893 star | **评测方法论索引**：涵盖 "if you can eval it, you have built it"、model/harness/skill 分解、eval⇄capability⇄RL 环境等 2026 年主流观点，团队建设评测能力的必读 |
| `ifixai-ai/iFixAi` | 15k star | **独立审计 agent**：对 agent 做对抗式检查、给出评分与盲点报告，作为上线前第三方审计的思路很好 |
| `ethz-spylab/agentdojo`（837）、`NVIDIA/garak`（v0.17.0，9.3k）、`Azure/PyRIT` | — | 提示注入/红队专项评测 |
| `mizcausevic-dev/agent-canary` 等小型项目 | — | 影子/渐进发布的参考实现（生态尚不成熟，多为自建） |

### 7.3 门禁设计（可直接抄）

**PR 门禁（每次提交）**
- 静态检查：Prompt 是否被硬编码在代码里（禁止）、工具是否有超时与重试、是否有步数上限。
- 单测：工具函数单测（确定性部分必须 100%）。
- **小评测集**（20–50 例，3 分钟内）：快速回归，允许"分数不得低于基线 -2%"。

**发布门禁（每次上线，T1/T2 强制）**
- 全量回归集（≥300 例，含多轮与工具）通过率不低于基线。
- 关键指标不退化：任务成功率、工具错误率、p95 延迟、单任务成本。
- **失败模式对比**：新增失败模式需评审（`agents-cli eval analyze` 会做失败模式聚类，可借鉴）。
- 安全评测：提示注入/越权工具调用专项集通过。
- 成本回归：单任务成本不得超基线 +15%。

**灰度门禁（放量判据）**
- 影子流量（不返回给用户）跑 24h：新旧版本在同一输入上的差异率 < 阈值。
- 小流量 A/B：成功率、升级人工率、成本三项均不劣化才允许放量。
- 任一 SLO 击穿 → **自动回滚 + 冻结该 agent 的自动发布**。

### 7.4 线上 trace → 评测数据集的自动采集链路（2026-09 实测）

**结论先行**：不存在"端到端全自动、拿来即用"的开源项目。可行形态是分段拼装：

- **第 1 段（成熟，可自托管）**：观测平台内置 `trace → dataset` 通道（UI 一键 / 批量 / SDK）。
- **第 2 段（早期，需自写规则）**：线上失败与难例的自动挖掘。
- **第 3 段（必须自建）**：采样 / 脱敏 / 标注复核 / 漂移治理 —— **这四件事没有任何开源项目替你做好**。

#### a) 观测平台内置的 trace→dataset 能力（已核对官方文档/README）

| 项目 | 机制 | 适用 |
| --- | --- | --- |
| `langfuse/langfuse`（35k） | Datasets 页支持 `Add from trace`、`Add batch from observations table`，可脚本批量从线上 trace 建回归集 | 默认首选 |
| `mlflow/mlflow`（28k） | 文档明确把 "Existing traces" 列为评测集来源；UI 勾选 trace → `Export traces to evaluation dataset`；SDK 用 `search_traces()` 检索后 `eval_dataset.merge_records()` | 已有 MLOps 体系 |
| `wandb/weave` | 支持把 trace、以及 agent 的 turns/tool calls 加入 Dataset | agent 逐步数据 |
| `lmnr-ai/lmnr` | **Signals**：用自然语言写规则扫每条完整 trace（每次 LLM turn、工具调用、子 agent、重试、错误），命中即产出结构化事件并回链 trace | **目前最接近"自动挖样本"** |
| `Arize-ai/phoenix` | OTel/OpenInference 原生，datasets + experiments 完整 | 已按 OTel 埋点 |
| `langwatch/langwatch`、`future-agi/future-agi` | 前者含 Scenarios 模拟；后者 README 明确 "Production traces feed back as training data" | 备选 |

#### b) "线上失败 → 回归测试" 专项小项目（**仅作设计参考**）

- `Jwuthri/Tracely-ai`（MIT）：链路为 `production trace → failure detection → regression test → CI gate`，明确反"手写数据集"。
- `trace2test`、`tracetape`、`jashshah999/agenteval`、`hoomanesteki/tracegym`、`OriginalByteMe/langfuse-dataset-curator`。
- 风险：star 低、多为单人维护、部分未声明许可证。**只抄思路，不进生产链路。**

#### c) 只有采集层（数据集层需自己接）

`traceloop/openllmetry`、`openlit/openlit`、`Helicone/helicone`、`AgentOps-AI/agentops`、`Arize-ai/openinference` —— 负责按 OTel GenAI 收 trace，后端仍需对接 Langfuse / MLflow / Phoenix。

#### d) 三个必须自建的闸门（决定数据集能否进门禁）

1. **采样 + 脱敏**：全量入集既贵又违规。按 agent/版本/租户/失败类型做分层采样 + 会话级去重 + PII 脱敏，**在 trace 落库前完成**。
2. **自动标注 + 人工复核**：LLM-as-judge 自动打标必须配复核队列（Langfuse annotation queue、Laminar 标注 UI）。**未复核样本只能进"难例候选池"，不得直接进发布门禁。**
3. **数据集版本 + 漂移检测**：线上分布会漂。回归集需版本化 + TTL + 定期重采样；持续监控集内输入分布与线上分布的距离，超阈值告警。

#### e) 推荐拼装

`Langfuse`（或 `MLflow` / `Phoenix` 二选一）做底座 → `Laminar Signals` 挖失败样本 → `deepeval` / `Ragas` 生成断言与合成场景 → 自研 harness 接 CI 门禁。数据集层对应 7.1 的"**难例集(线上捞)**"。

#### f) 许可证提醒（已核对 LICENSE 原文）

- `Arize-ai/phoenix`：**Elastic License 2.0（ELv2），非 OSI 标准开源**，商用前须法务确认。
- `langfuse/langfuse`：核心 MIT + `ee/`、`web/src/ee/`、`worker/src/ee/` 目录走商业许可（版权方 ClickHouse, Inc.）。
- 其余项目（MLflow / Weave / deepeval / Ragas 等）许可证需逐个核实后再纳入。

---

## 8. L5 发布与进版：把"agent 变更"变成一个可回滚的单元

### 8.1 一次发布的完整制品清单（必须原子绑定）

| 制品 | 载体 | 回滚风险 |
| --- | --- | --- |
| ① Agent 代码 | 容器镜像（digest 固定） | 低 |
| ② Prompt / 指令包 | Prompt 仓库（版本化 + 变量 schema） | 低 |
| ③ 模型与参数 | manifest 声明（含 fallback 链） | 中（行为差异大，需评测兜底） |
| ④ 工具 / MCP server 版本 | `mcp://server@version` | **高**（schema 变更会让在途任务失败） |
| ⑤ 记忆 schema / 检索索引 | 迁移脚本 + 版本号 | **最高**（回滚后读写不兼容） |
| ⑥ 策略 / 护栏包 | 策略仓库（Cedar/CEL/配置） | 中 |
| ⑦ 评测集版本 | 数据仓库 | 低（但要与新版本绑定存档） |

> **业界范式**：Azure Foundry 用 **agent version + stable endpoint**；LangSmith 用 **revision**；AgentCore Optimization 用 **versioned configuration bundle**。三者本质相同：**一次发布 = 一个不可变配置包 = 一个可回滚单元。**

### 8.2 发布策略对比与选择

| 策略 | 成本 | 适用 | 注意 |
| --- | --- | --- | --- |
| 影子（shadow） | 高（双倍调用） | T2 关键 agent、有副作用工具需 mock | 工具调用需"干跑"模式，否则会重复下单 |
| 灰度/金丝雀（按流量% 或 用户稳定分桶） | 低 | 通用首选 | **必须按 conversation 粘性路由**，同一会话不能跨版本 |
| A/B（按 prompt/工具描述/模型切分） | 中 | 优化场景 | 网关层做，AgentCore Optimization、Langfuse 实验均可实现 |
| 特性开关（feature flag） | 极低 | 关闭某个工具/子能力/kill switch | **每个 agent 至少有一个"急停开关"** |
| 蓝绿 | 中 | 大版本切换 | 状态迁移仍是难点 |

**推荐默认组合**：`评测门禁 → 灰度 5%（粘性会话）→ 观测 24h → 25% → 100%`，任一门禁击穿自动回滚；同时常驻一个 **kill switch**（网关侧一键禁用该 agent 的全部工具）。

### 8.3 版本化与回滚的工程细节（最容易踩坑）

- **Prompt 必须离开代码**：Prompt 仓库 + 变量 JSON Schema + 变更 diff 评审；Prompt 变更走与代码相同的 PR 流程。
- **工具契约测试**：为每个 MCP server/tool 建契约测试（入参/出参/错误码），工具升级时先跑契约测试 + 所有下游 agent 的评测集。
- **在途任务兼容**：发布前必须回答"正在执行的长任务怎么办"——持久化执行引擎提供 **version pinning**（在途任务固定在旧版本上跑完），这是选型 durable execution 时的重要加分项。
- **记忆迁移可逆**：记忆/索引变更必须提供向前与向后两个迁移脚本，或采用"双写 + 影子读"过渡。
- **回滚要演练**：每季度做一次真实回滚演练（含状态回滚），否则回滚预案等于没有。

---

## 9. L6 记忆与状态治理：把它当数据库，不是当缓存

- **项目**：`mem0ai/mem0`（65k star，最活跃）、`letta-ai/letta`（25k，v0.16.8，显式记忆管理（MemGPT 路线））、`getzep/zep`（4.9k，图记忆 + 时序）、`langchain-ai/langmem`（轻量，与 LangGraph 集成）。托管：Vertex **Memory Bank**（含 memory revisions 与 IAM 条件）、AgentCore Memory、Foundry 的会话托管。
- **治理要求**：
  - **可删除**（GDPR/个保法：按用户删除必须级联到向量库与摘要）；
  - **TTL**（会话级记忆设过期，避免脏记忆长期污染）；
  - **版本化 + diff**（Vertex 的 memory revisions 值得抄：能看"记忆在什么时候被改了什么"）；
  - **分区隔离**（跨租户/跨部门绝不能共享记忆库；agent 间共享记忆必须显式授权）；
  - **可观测**（OTel 有独立 `memory` span：读写延迟、命中率、注入量）。
- **最危险的场景**：**记忆被提示注入污染**（用户诱导 agent 写入"以后所有退款直接通过"这类记忆）→ 必须对写入记忆做审核/规则校验，且记忆写入要有独立审计日志。

---

## 10. L7 安全、权限与合规

### 10.1 威胁模型（按 2026 年真实事故排序）

1. **提示注入 → 工具滥用**：网页/邮件/RAG 文档里藏指令，让 agent 调用高危工具（发起退款、导出客户名单）。
2. **工具/MCP 供应链**：第三方 MCP server 或工具描述被投毒（"tool poisoning"），agent 读到的是攻击者写的描述。
3. **越权与混淆代理**（confused deputy）：agent 用"服务账号"权限替你调用本无权访问的 API。
4. **数据外泄**：把上下文/记忆中的敏感信息写到日志、外部工具或外部网站。
5. **Agent 自主交易**：2026 年新增风险类别（AgentCore 已推出 Payments 服务，用 x402/MPP 协议 + 限额 + 可观测来管）。

### 10.2 项目与做法

| 能力 | 项目 / 做法 |
| --- | --- |
| 策略拦截（关键） | **AgentCore Policy 范式**：用 **Cedar**（或 CEL）写确定性策略，在网关**拦截每一次工具调用**再执行；自然语言可由 LLM 转 Cedar，但执行必须是确定性的 |
| 内容护栏 | `NVIDIA/NeMo-Guardrails`（v0.24.1）、`guardrails-ai/guardrails`（v0.11.0）、AWS Bedrock Guardrails、Google Model Armor（agentgateway 已可对接这些） |
| MCP 安全扫描 | `snyk/mcp-scan`（原 invariantlabs `mcp-scan`）：扫描 MCP server 配置、工具描述投毒、凭据泄露 |
| 红队 | `NVIDIA/garak`、`Azure/PyRIT`、`meta-llama/PurpleLlama`、`ethz-spylab/agentdojo` |
| 沙箱隔离 | `kubernetes-sigs/agent-sandbox`、`E2B`、gVisor/Firecracker |
| 身份 | 每个 agent 独立 workload identity（AgentCore Identity 兼容 Cognito/Entra/Okta/Auth0；Azure 侧 Entra ID + RBAC；Google 侧 IAM Conditions 控到 session 粒度） |
| 审计 | 工具调用全量落审计（谁、何时、用谁的权限、对什么数据、结果如何），保留期按合规要求 |

### 10.3 最小强制要求（建议写进上线门槛）

- 工具按"只读 / 写 / 高危"三级分类，**高危工具必须人工确认或双人授权**。
- 所有工具调用有**幂等键**与**干跑模式**（供影子测试）。
- 模型/工具出网一律走网关，**业务侧不落地任何真实凭据**。
- PII 数据不得进入 prompt 日志与第三方观测平台（在网关做脱敏或选可私有化部署的观测）。
- 交付 **MCP server SBOM**，锁定版本与来源（对应 MCP Registry 的"发布-审核-批准"流程思路）。

---

## 11. L8 成本与容量治理

**四道防线（缺一不可）**

1. **硬预算**（网关）：按部门/agent/用户/会话设置 token 与金额上限，超限拒绝并告警。这是唯一能防"账单事故"的措施。
2. **模型路由**：简单请求走小模型（`semantic-router`、Tiered routing），复杂任务才升级；网关统一 fallback 链。
3. **缓存**：Prompt Caching（长 system prompt 必备）、语义缓存（相似问重复答）、工具结果缓存（检索/查询类）。
4. **循环控制**：最大步数、最大工具调用次数、子 agent 数量与深度上限、上下文压缩阈值（对应 `gen_ai.conversation.compacted` 事件可观测）。

**归因**：把 trace 上的 token 映射到 `cost.center`/部门/agent 版本，做**"按业务部门出账 + 异常会话 Top N"**，否则成本优化永远推不动。

**容量**：agent 流量特征是"突发 + 长尾"，配合沙箱的 scale-to-zero（Dapr Agents/agent-sandbox 都支持）能显著降低成本。

---

## 12. L9 事故响应与 On-call：为非确定性系统设计 SRE

### 12.1 Agent 的"症状 → 病因"速查表

| 症状 | 首要怀疑 | 处置 |
| --- | --- | --- |
| 任务成功率骤降 | 模型/工具/记忆三者之一变更 | 对比版本 → 回滚最近一次变更 |
| `inference_calls` / `tool_calls` 飙升 | agent 陷入循环/工具返回不可解析 | 开步数硬上限，禁用该工具 |
| 成本异常（单会话） | 长上下文 + 循环 + 无上限 | 终止会话，检查是否被恶意构造 |
| 输出"看起来对但错了"（静默失败） | Prompt/检索/模型漂移 | 依赖**在线采样评测** + 用户负反馈埋点发现 |
| 工具大面积超时 | 下游系统或 MCP server 版本问题 | 网关熔断 + fallback 工具 |
| 合规事件（越权/数据外泄） | 提示注入 / 权限过宽 | 立即 kill switch + 审计取证 + 通知合规 |

### 12.2 必备机制

- **SLO 与错误预算**：任务成功率、升级人工率、p95、成本/task 四项作为 SLO；错误预算烧完 → 冻结自动发布。
- **Trace 回放**：任何事故必须能用 trace 完整回放（含输入、每步决策、工具入参出参、模型响应），这是 agent 运维与微服务运维最大的区别。
- **Kill Switch**：网关侧一键禁用某 agent/某工具/某 MCP server，秒级生效（不要依赖发版）。
- **人工兜底**：**"升级给人工"必须是一等公民**，且要监控升级率——升级率飙升通常是最早的质量劣化信号。
- **值班分层**：平台值班（运行时/网关/观测）、业务值班（agent 行为）、模型供应商通道（限流/故障公告）。
- **复盘模板**：需包含"是模型问题、Prompt 问题、工具问题、数据问题、还是编排问题"，并沉淀为新的评测用例（**每个事故都要变成一条回归测试**）。

---
## 13. 厂商托管平台对比（2026-09 官方文档实测）

三家云厂商已把上述 L1–L9 做成了产品。**对平台团队的意义：先抄它们的抽象，再决定自建哪些。**

### 13.1 AWS Bedrock AgentCore

| 服务 | 能力（官方描述要点） | 对标的自建组件 |
| --- | --- | --- |
| **Harness** | 托管 agent loop，一次 API 调用定义模型/系统提示/工具；**每 session 一个隔离 microVM**，带文件系统与 shell | 运行时 + 沙箱 |
| **Runtime** | Serverless 运行时，快冷启动、长时异步、**真会话隔离**、内置身份；支持 CrewAI/LangGraph/LlamaIndex/ADK/OpenAI Agents/Strands，支持 MCP 与 A2A | K8s 运行时 + 网关 |
| **Memory** | 短期 + 长期记忆，跨 session 持久，**记忆库可跨 agent 共享并"从经验中学习"** | mem0/Zep 等 |
| **Gateway** | 把 API/Lambda/已有服务转成 MCP 工具，并连接既有 MCP server | MCP 网关 / ContextForge |
| **Identity** | Agent 身份与鉴权，兼容 Cognito/Okta/Entra/Auth0 | workload identity |
| **Code Interpreter / Browser** | 隔离代码执行沙箱 / 托管浏览器（Playwright、BrowserUse） | E2B / agent-sandbox |
| **Observability** | OTel 标准遥测，可视化 trace 与执行路径 | Langfuse/Phoenix |
| **Evaluations** | 面向 agent 的自动化评测服务，支持 session/trace/span 级评测 | deepeval/promptfoo |
| **Optimization** | **用 AI 生成改进建议 + 版本化配置包 + A/B 实验**（经 Gateway 做流量切分），优化系统提示与工具描述 | 自建实验平台 |
| **Policy** | **自然语言或 Cedar 写细粒度策略，通过 Gateway 拦截每一次工具调用** | 自研策略引擎 / OPA |
| **Registry** | 企业级目录：agent / MCP server / tool / skill 的发现、**发布-审核-批准治理流程**、语义+关键词混合检索 | 自建注册中心 |
| **Payments** | agent 微支付（x402 / MPP 协议），限额与可观测 | — |

> **重点**：`Policy + Registry + Optimization + Evaluations` 这四件套就是"agent 上线治理"的完整答案，**建议直接照抄概念模型**（哪怕底层自建）。

### 13.2 Microsoft Foundry Agent Service

- **两种 agent 类型**：`Prompt agents`（纯配置，零代码零基础设施）与 `Hosted agents`（自带容器/框架：Agent Framework、LangGraph、OpenAI Agents SDK、Anthropic Agent SDK、Copilot SDK）。
- **Agent Runtime**：托管会话、工具调用与 agent 生命周期、自动扩缩容。
- **Toolboxes**：工具集合一次编排（web/file search、code interpreter、MCP server、自定义函数），**通过单一托管 MCP 端点共享，集中鉴权、治理与版本化**。
- **Observability**：端到端 trace、指标、评测 + Application Insights。
- **Optimization（预览）**：agent optimizer 自动生成更好的 instructions、skills、工具描述与模型选择。
- **Identity & Security**：Entra 身份、RBAC、内容过滤、VNet 隔离。
- **Publishing**：**版本化 agent + 稳定端点**，并可发布到 Teams / M365 Copilot / **Entra Agent Registry**。

### 13.3 Google（Vertex AI / Gemini Enterprise Agent Platform）

- **Agent Runtime**（含吞吐/延迟调优参数、**Agent Gateway 统一入口**、Private Service Connect 私网接入）；部署目标含 Agent Runtime / Cloud Run / GKE。
- **Sessions**（会话状态，IAM Conditions 可控制到 session 粒度）、**Memory Bank**（长期记忆，**支持查看 memory revisions**）、**Example Store**、**Code Execution 沙箱**、**Feedback Service**（把用户反馈与 trace 事件对齐）。
- **Agent evaluation** 与合规矩阵明确到服务粒度（VPC-SC / CMEK / 数据驻留 / HIPAA）。
- **`agents-cli`**（`uvx google-agents-cli setup`）：把 `create → eval run/grade/compare/analyze/optimize → deploy → publish` 做成 CLI，并**以"技能包"形式注入 Claude Code / Codex / Antigravity 等编码 agent**，提供 `infra cicd` 一键生成 staging/prod 流水线。**Agent Starter Pack 已进入维护模式并迁移到 agents-cli。**
- 生态背书：OTel GenAI 语义约定仓库中已有 `google-adk`、`aws-bedrock-agentcore`、`azure-ai-foundry`、`openai-agents`、`crewai`、`langchain`、`llamaindex`、`haystack`、`pydantic-ai`、`dspy`、`litellm` 等场景参考实现——**这些是"埋点怎么接"的最佳抄写素材**。

### 13.4 自建 vs 托管：决策建议

| 情形 | 建议 |
| --- | --- |
| 已重度使用某云 + 数据不出云 | **用该云的托管平台做运行时/网关/评测**，自建只做"注册中心 + 组织级门禁" |
| 多云 / 混合云 / 数据合规要求私有化 | **自建为主**：网关(agentgateway/Higress) + 观测(Langfuse) + 评测(deepeval/promptfoo) + 运行时(K8s agent-sandbox + durable execution) |
| 想快速见效（0–3 个月） | 先落地：**统一网关 + 统一观测 + 评测门禁 + 注册表(先用 Git+CI 实现)**，这四件事不用等平台建设 |
| 长期 | 抽象必须自持：**agent manifest、策略语言、trace schema 掌握在自己手里**，避免厂商锁定 |

---

## 14. 选型矩阵（能力 → 首选 / 备选）

| 能力 | 首选（开源） | 备选 / 托管 |
| --- | --- | --- |
| Agent 可观测 + 评测一体化 | **Langfuse v4** | Opik、Phoenix、Coze Loop、MLflow 3、LangSmith |
| 埋点标准化 | **OpenTelemetry GenAI semconv + OpenInference/OpenLLMetry** | OpenLIT |
| LLM/MCP/A2A 网关 | **agentgateway v1.5**；国内 **Higress** | LiteLLM、Envoy AI Gateway、Portkey、Kong、TensorZero |
| MCP 注册 + 工具联邦 | **IBM ContextForge** | MCP Registry（官方）、Higress MCP Hosting、genai-toolbox |
| 持久化执行 | **Temporal** / **Restate** | Dapr Agents、Inngest、Hatchet、DBOS |
| K8s agent 运行时/沙箱 | **kubernetes-sigs/agent-sandbox v1.0.2** | kagent、E2B、AgentCore Runtime、Foundry Hosted Agents |
| 评测 / 门禁 | **deepeval + promptfoo** | inspect_ai、Langfuse Evals、AgentCore Evaluations |
| 红队 / 安全评测 | **garak + PyRIT + agentdojo** | iFixAi、AgentCore Policy 思路 |
| MCP 供应链安全 | **snyk/mcp-scan** | Registry 审核流程 + SBOM |
| 护栏 | **NeMo Guardrails / Guardrails AI** | Bedrock Guardrails、Model Armor |
| 记忆 | **mem0** | Zep、Letta、LangMem、Vertex Memory Bank |
| Prompt 管理 | **Langfuse Prompts** | Agenta、Coze Loop、agents-cli 的 prompt 优化 |
| 灰度 / 特性开关 | **OpenFeature + Unleash/GrowthBook/Flagsmith** | Argo Rollouts、LaunchDarkly |
| CI/CD | **Argo CD + Argo Rollouts** | Google `agents-cli infra cicd` 生成物 |
| 自建/托管推理 | **vLLM / SGLang**（+ semantic-router） | 云上模型服务 |
| Agent 注册中心 | Git 仓库 + CI（起步）→ 参考 AgentCore Registry / Entra Agent Registry 设计 | MCP Registry、ContextForge |

---

## 15. 落地路线图（平台团队 6 个月）

### 第 1 阶段：0–30 天 —— 立标准、看得见
- [ ] 发布 **`agent.yaml` manifest 规范**（含 tier、SLO、数据等级、制品清单）与 agent 命名规范。
- [ ] 发布 **OTel GenAI 埋点强制规范**（agent.name/version/conversation.id/tool 版本命名）并提供 SDK 封装包。
- [ ] 上线**统一观测平台**（Langfuse 或复用已有），接入 ≤3 个试点 agent，打通 trace。
- [ ] 建立 **Agent 注册表（先用 Git 仓库 + CI 校验实现）**，摸清"到底有多少 agent 在上线"。
- [ ] 定义 **T0/T1/T2 分级与对应门禁**，并公示。

### 第 2 阶段：30–90 天 —— 收口流量、建立门禁
- [ ] 上线 **统一 AI/MCP 网关**：虚拟 Key、配额预算、模型 fallback、护栏、trace 透传；**下线业务侧直连模型 Key**。
- [ ] 上线 **评测服务**：回归集模板 + 评分器库（含 LLM-judge rubric）+ `deepeval/promptfoo` 流水线。
- [ ] 在 CI 中启用 **PR 小评测集门禁**；发布前 **全量回归门禁**。
- [ ] 提供 **"黄金路径"模板仓库**（含 Dockerfile、OTel、任务 API、CI/CD、Terraform）。
- [ ] 建立 **kill switch**（网关侧一键禁用 agent/工具）。

### 第 3 阶段：90–180 天 —— 灰度、策略、优化闭环
- [ ] 灰度发布能力：粘性会话分流 + 影子模式 + 自动回滚判据。
- [ ] **工具级策略拦截**（CEL/Cedar）：工具分级 + 高危人工确认 + 幂等键 + 干跑模式。
- [ ] **记忆治理**：TTL、可删除、版本化、跨租户隔离 + 审计。
- [ ] **成本归因与出账**：按部门/agent 版本出账，异常会话告警。
- [ ] **优化闭环**：prompt/工具描述的 A/B 实验（网关流量切分）+ 自动优化建议。
- [ ] 事故演练：trace 回放 + 真实回滚 + kill switch 演练，每季度一次。

### 平台团队运营机制（比技术更重要）
- **Agent 上线评审会**（T1/T2 必过）：15 分钟，看评测报告 + 安全报告 + 回滚预案。
- **成熟度记分卡**：对每个 agent 打分（埋点、评测、灰度、策略、成本、runbook），与资源/模型配额挂钩。
- **事故用例回流**：每个线上事故必须新增回归用例，沉淀为平台级资产。
- **禁止清单**：直接写进规范——"prompt 硬编码在代码"、"业务直连模型 Key"、"高危工具无审批"、"无步数上限"、"无 trace 的生产 agent"。

---

## 16. 反模式清单（审查 agent 时逐条对照）

1. Prompt 硬编码在代码里，改一句话就要发版。
2. 上线没有评测集，靠"我试了一下挺好的"。
3. 换模型/升级框架不做回归评测（模型漂移是最大的静默失败来源）。
4. Agent 没有步数/工具调用次数上限，可能无限循环烧钱。
5. 共享一个模型 API Key，没有配额与预算上限。
6. 高危工具（退款、下单、发消息、删数据）无审批、无干跑、无幂等键。
7. 记忆无 TTL、无删除接口、跨租户共用。
8. 没有 trace 或 trace 不完整（只看最终输出）。
9. 灰度按用户维度而非会话维度切分，导致同一会话跨版本行为错乱。
10. 回滚只回滚镜像，不回滚 prompt/工具/记忆。
11. 只监控"服务是否活着"，不监控"任务是否成功"。
12. 把 agent 当成无状态 HTTP 服务部署（无持久化执行，一崩全崩）。
13. 让 agent 直接操作生产数据库/生产账号权限。
14. 把安全限制写在 prompt 里（"不要泄露客户数据"），而没有确定性策略。

---

## 17. 关键参考与一手材料

**标准与协议**
- OpenTelemetry GenAI 语义约定（已迁移）：`github.com/open-telemetry/semantic-conventions-genai`（含 `gen-ai-agent-spans.md`、`gen-ai-metrics.md`、`gen-ai-events.md`、`mcp.md`，以及各框架场景示例）
- Model Context Protocol 规范（最新发布 2026-07-28）与 MCP Registry（v1.8.1，API v0.1 冻结，走向 GA）
- A2A 协议 v1.0.1（26k star，Linux Foundation）
- OpenFeature（特性开关标准）

**方法论（2026 年新出现的优质读物）**
- `benchflow-ai/awesome-evals`：评测方法论索引（"if you can eval it, you have built it"、model/harness/skill 分解、eval⇄capability⇄RL 环境、eval 栈分层）
- `Meirtz/Awesome-Context-Engineering`：上下文工程综述（含已发表 arXiv 论文），从静态 prompt 演进到 agent runtime / memory / protocol / 可观测
- `e2b-dev/awesome-ai-sdks`：agent SDK/监控/调试/部署工具全景数据库

**本仓库内的取证材料**
- `research/gh_scan_1.txt`、`research/gh_scan_2.txt`：GitHub 实时检索结果（含 star、最近提交时间）
- `research/gh_scan_eval.txt`、`research/readme_scan.ps1`、`research/docs_scan.ps1`、`research/lic_check.ps1`：7.4 节取证过程（"trace→数据集"关键词检索、候选项目 README 与官方文档抓取、LICENSE 原文核对）
- `research/meta.txt`：56 个核心项目的 star / 最新 release / 最近提交 / 许可证
- `research/pages/`、`research/pages3/`：102 个项目 README 原文
- `research/otel/`：OpenTelemetry GenAI 语义约定规范全文
- `research/vendor/`：AWS AgentCore / Azure Foundry / Vertex Agent Engine / Google agents-cli / LangSmith 官方文档摘录

**生态信号（值得关注，尚未纳入选型）**：`paperclipai/paperclip`（81k star，v2026.916.0，"管理工作中 agent 的应用"）与 `ifixai-ai/iFixAi`（v4.0.0，15k star，"独立审计 agent"）代表 2026 年两个新方向：**agent 的日常运营管理界面**与**第三方独立审计**；后者的"审计-评分-盲点报告"模式非常适合抄进内部上线评审流程。

**说明**：所有 star 数、版本号均为 2026-09-17 实测快照，会随时间变化；厂商能力描述以官方文档原文为准，落地前建议再核对一次（AgentCore / Foundry 的预览功能迭代很快）。
