# OTel GenAI 埋点规范 v0.1

| 项目 | 内容 |
| --- | --- |
| 文档名称 | OTel GenAI 埋点规范（OpenTelemetry GenAI Instrumentation Profile） |
| 版本 | v0.1 |
| 状态 | Draft / 评审中（可供内部试点，尚未冻结） |
| 适用范围 | 所有接入 LLM / Agent / MCP 的应用与服务 |
| 强制范围 | 按第 3 章分级执行（T0 / T1 / T2） |
| 上游依据 | `open-telemetry/semantic-conventions-genai`，快照见本仓库 `research/otel/` |
| 上游成熟度 | **全部条目为 `Development`（非 `Stable`）** —— 见 2.3 |
| 维护责任 | 平台工程（Platform Engineering） |
| 评审周期 | 每季度复核一次上游变更，或收到破坏性变更通知时即时复核 |

**变更记录**

| 版本 | 日期 | 变更摘要 |
| --- | --- | --- |
| v0.1 | 2026-09-17 | 首次发布。基于上游 GenAI 语义约定快照建立公司内埋点子集与收紧规则 |

---

## 1. 目的与范围

### 1.1 目的

本规范把 OpenTelemetry 的 GenAI 语义约定（semantic conventions）转译为**公司内部可执行、可验收的强制标准**，解决四个问题：

1. **可运维**：任一 trace 都能回答"这次调用用了哪个模型、花了多少钱、慢在哪一步、错在哪一层"。
2. **可归因**：成本与延迟能沿 trace 归因到业务部门、agent、工具与版本。
3. **可对比**：不同框架（LangChain / LangGraph / ADK / OpenAI Agents / 自研）产出的遥测字段一致，看板与告警只写一套。
4. **可合规**：prompt 与响应内容默认不落遥测，需要时按既定模式开启并受访问控制约束。

### 1.2 范围

本规范覆盖以下操作的埋点要求：

- 模型推理、嵌入（embeddings）、检索（retrieval）、记忆（memory）、响应取回（fetch response）
- Agent 创建、调用、工作流编排、规划
- 工具执行（含 MCP 工具）
- 上述操作的指标、事件与异常

本规范覆盖埋点的**数据结构**（span 名、属性键、指标名、事件名、枚举值）与**行为规则**（何时开启、何时禁止、如何关联）。不覆盖采集与后端选型。

### 1.3 非目标

- 不定义 SDK API。埋点通过 OTel 官方/社区 instrumentation 或平台封装的 `otel-genai` 包完成。
- 不定义后端（Langfuse / Phoenix / 自建）的部署形态。
- 不替代评测规范。评测**结果**如何写入 trace 由第 10 章约束，评测集与评分器设计另行规定。
- 不覆盖大模型训练与微调的可观测性。

### 1.4 规范性用语

| 用语 | 含义 |
| --- | --- |
| **必须（MUST）** | 无条件要求。违反即为不合规，CI 应阻断发布 |
| **必须不（MUST NOT）** | 无条件禁止 |
| **应当（SHOULD）** | 推荐做法。偏离必须在本服务的 `observability.md` 中记录理由 |
| **可以不（MAY）** | 可选 |

本规范中出现 `【本地收紧】` 标记的条目，表示该要求**比上游规范更严格**。未标注的条目直接继承上游规范。当上游在**本规范未收紧**的领域发生变更时，以上游为准；当上游变更**触及本规范已收紧**的领域时，按第 14 章走变更流程。

### 1.5 术语

| 术语 | 含义 |
| --- | --- |
| Agent | 具备"推理 + 工具调用 + 自主规划"能力的 GenAI 应用单元 |
| Span | 一段有起止时间、可嵌套的操作记录 |
| Trace | 由同一根操作串起的一棵树形 span 集合 |
| 埋点 | 在代码中产生遥测数据的行为（instrumentation） |
| T 级别 | 服务的生产关键度分级，见第 3 章 |

---

## 2. 与上游规范的关系

### 2.1 权威来源

上游规范已从 `open-telemetry/semantic-conventions` 主仓库迁出，独立为 **`open-telemetry/semantic-conventions-genai`**。本规范的字段定义**不在本仓库内另行发明**，凡上游已定义的键名、枚举值、指标名，一律以上游为准。

本仓库 `research/otel/` 保存了本规范制定时的上游全文快照，作为对账基线。

### 2.2 本规范是"子集 + 收紧"

本规范与上游的关系是三层：

1. **子集**：上游有但本组织暂不使用的操作（例如暂不落地的多模态生成），本规范不予要求。
2. **收紧**：把上游的 `Recommended` 提升为本地 `必须`，把上游允许的自定义取值收窄为白名单。
3. **补充**：上游未规定、但本组织运营必需的字段与关联规则（如部门归因标签）。

**任何团队不得自行扩展 `gen_ai.*` 命名空间。** 需要新字段时走第 14 章流程。

### 2.3 上游 `Development` 状态的应对策略

上游 GenAI 约定的全部条目目前均为 **`Development`**，意味着字段名与语义**仍会发生破坏性变更**。这不是"可以再等等"的理由，而是"必须现在就封装"的理由。

**【本地收紧】三条强制要求：**

1. **埋点封装隔离**：业务代码**必须不**直接书写 `gen_ai.*` 字符串字面量。所有属性键必须来自平台发布的 `otel-genai` 常量模块或封装函数。上游重命名时，改造范围收敛到一个包。
2. **版本锁定与台账**：平台**必须**维护"上游版本 → 本地映射"台账，记录每次上游破坏性变更及本地适配状态（格式见附录 D）。
3. **CI 漂移检测**：平台**应当**用上游的 registry 模型配合 OTel Weaver 做 schema 校验，使上游漂移在 CI 中显性失败，而不是在生产看板上表现为"某个字段突然空了"。

---

## 3. 分级与强制范围

服务按生产关键度分为三级，各级的最小埋点集不同。

| 级别 | 定义 | 最小埋点集 |
| --- | --- | --- |
| **T0** | 内部试用、Demo、实验 | trace 骨架：agent span + inference span + 基础用量 |
| **T1** | 生产、可容忍有损 | T0 + 工具 span + 检索/记忆 span + 全量指标 + 采样属性 + 成本归因标签 |
| **T2** | 生产、关键业务 / 涉及资金或对外承诺 | T1 + 事件（评测与压缩）+ agent 版本三件套联动发布 + 合规审计字段 |

分级只决定**最小集**，不限制做更多。各级共同遵守"必须不"条款（第 4.3 节、第 8 章）。

---
## 4. 通用要求

### 4.1 一条 trace 必须回答的问题

无论 T 级别如何，一条 GenAI trace **必须**能回答：

1. **谁在调用**：哪个 agent、哪个版本、哪个部门。
2. **调用了什么**：哪个 provider、哪个模型、什么采样参数。
3. **花了多久**：端到端耗时，以及耗时在规划 / 模型 / 工具 / 检索之间的分布。
4. **花了多少**：输入与输出 token 数，能按模型价格折算成本。
5. **是否出错**：错误发生在哪一层，错误类型是什么。

若某条 trace 无法回答其中任一问题，视为埋点不完整。

### 4.2 Span 创建规则

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-4.2.1 | 采样相关属性**必须**在 **span 创建时**传入，不得事后 `set_attribute` | 必须 |
| GEN-4.2.2 | Span **必须**在操作**发起前**创建，在响应**完整接收或确定失败**后结束 | 必须 |
| GEN-4.2.3 | 一个 span **必须**覆盖整个逻辑操作，**包含自动重试**的耗时。不得为每次重试创建平级 span | 必须 |
| GEN-4.2.4 | 流式请求的 span **必须**在流结束（或客户端放弃）时结束 | 必须 |
| GEN-4.2.5 | 上下文**必须**透传：同一逻辑链路上的 agent 调用、工具调用、模型调用必须落在同一 trace 树内 | 必须 |
| GEN-4.2.6 | 后端或网关的内部实现细节**应当不**出现在 span 名中 | 应当 |
| GEN-4.2.7 | 禁止为"仅用于日志"的目的创建零耗时 span | 必须不 |

**原因说明（GEN-4.2.1）**：尾部采样（tail-based sampling）在 span 结束后才做决策。创建时未携带的属性不能被采样器看到，会导致"高成本 trace 未被采样"。

### 4.3 全局禁止事项

| 编号 | 禁止内容 | 级别 |
| --- | --- | --- |
| GEN-4.3.1 | 禁止自造 `gen_ai.*` 之外的 GenAI 专用命名空间（如 `mymodel.*`） | 必须不 |
| GEN-4.3.2 | 禁止把无界基数的值写入 span 名或指标标签（如把用户 ID、prompt 片段写入 span 名） | 必须不 |
| GEN-4.3.3 | 禁止在默认配置下采集 prompt / 响应 / 系统指令 / 工具参数与结果 | 必须不 |
| GEN-4.3.4 | 禁止用生成的 UUID、trace id 或内容哈希充当 `gen_ai.conversation.id`（见 6.2） | 必须不 |
| GEN-4.3.5 | 禁止在没有实际可用计数值时伪造 token 用量 | 必须不 |
| GEN-4.3.6 | 禁止在 `fetch_response` 类操作上上报 token 用量（该操作不产生推理） | 必须不 |

---

## 5. Span 规范

### 5.1 通用规则

**命名格式**（`{...}` 为占位符）：

| 操作 | Span 名格式 |
| --- | --- |
| 模型推理 | `{gen_ai.operation.name} {gen_ai.request.model}` |
| 创建 agent | `create_agent {gen_ai.agent.name}` |
| 调用 agent | `invoke_agent {gen_ai.agent.name}` |
| 工作流 | `invoke_workflow {gen_ai.workflow.name}` |
| 规划 | `plan {gen_ai.agent.name}` |
| 工具执行 | `execute_tool {gen_ai.tool.name}` |
| 检索 | `{gen_ai.operation.name} {gen_ai.data_source.id}` |
| 记忆 | 由实现按操作名定义 |
| MCP | `{mcp.method.name} {target}`；无低基数 target 时退化为 `{mcp.method.name}` |

**【本地收紧】** 上述格式为**强制**。当占位符不可用时（例如模型名未知），**应当**保留操作名部分，**必须不**用请求内容填充。

**Span Kind**：

| 操作 | Kind |
| --- | --- |
| 推理、嵌入、检索、记忆、创建 agent、调用 agent（跨进程）、工作流 | `CLIENT` |
| 同进程内运行的模型 / 记忆系统 | `MAY` 用 `INTERNAL` |
| `invoke_agent`（进程内框架调用） | `INTERNAL` |
| `execute_tool` | `INTERNAL` |

**Span Status**：按 OTel《Recording Errors》文档设置。业务语义上的"模型答错了"**不**等于 span 错误 —— 只有操作失败才置错误状态。

**【本地收紧】错误属性要求：**
- 操作失败时**必须**设置 `error.type`。
- `error.type` **必须**是低基数取值：provider 返回的错误码、客户端库的错误码、异常类名，或 `_OTHER`。
- **必须不**把异常 message 写入 `error.type`。
- **应当**同时记录异常事件（见 10.3），携带 `exception.type` / `exception.message` / `exception.stacktrace`。

### 5.2 强制埋点矩阵

| Span | T0 | T1 | T2 |
| --- | --- | --- | --- |
| 推理（inference） | 必须 | 必须 | 必须 |
| 创建 agent | 可以不 | 应当 | 必须 |
| 调用 agent（client / internal） | 必须 | 必须 | 必须 |
| 工作流（invoke_workflow） | 可以不 | 应当 | 必须 |
| 规划（plan） | 可以不 | 应当 | 必须 |
| 工具执行（execute_tool） | 可以不 | 必须 | 必须 |
| 检索（retrieval） | 可以不 | 必须 | 必须 |
| 记忆（memory） | 可以不 | 应当 | 必须 |
| 嵌入（embeddings） | 可以不 | 必须 | 必须 |
| 响应取回（fetch_response） | 可以不 | 应当 | 应当 |

**【本地收紧】** 框架不自动产生某条 span 时（例如自研工具函数），**必须**手工埋点补齐，不得以"框架不支持"为由缺项。

### 5.3 模型侧 span 必填属性

#### 5.3.1 推理（`chat` / `text_completion` / `generate_content`）

**必须**：

| 属性 | 说明 |
| --- | --- |
| `gen_ai.operation.name` | `chat` / `text_completion` / `generate_content` |
| `gen_ai.provider.name` | 见附录 A.2 |

**条件必须**：

| 属性 | 条件 |
| --- | --- |
| `gen_ai.request.model` | 可得时 |
| `error.type` | 操作失败时 |
| `gen_ai.conversation.id` | 库中存在真实会话标识时（见 6.2） |
| `gen_ai.output.type` | 客户端指定了输出类型时（`text` / `json` / `image` / `speech`） |
| `gen_ai.prompt.name` / `gen_ai.prompt.version` | 使用具名 prompt 模板时 |
| `gen_ai.request.stream` | 请求为流式时 |
| `gen_ai.request.choice.count` | 请求中包含且不等于 1 时 |
| `gen_ai.request.top_k` | 适用时 |
| `gen_ai.request.seed` | 请求中包含 seed 时 |
| `server.address` / `server.port` | 可通过网络观测时 |

**【本地收紧】提升为必须**（上游为 `Recommended`）：

| 属性 | 说明 |
| --- | --- |
| `gen_ai.usage.input_tokens` | 输入 token 数 |
| `gen_ai.usage.output_tokens` | 输出 token 数 |
| `gen_ai.response.model` | 实际响应模型（与请求模型可能不同） |
| `gen_ai.response.finish_reasons` | 停止原因数组 |

**【本地收紧】用量口径规则：**
- 供应商同时报告"计费 token"与"消耗 token"时**必须**上报**计费口径**。
- 上报了按模态拆分的用量（`gen_ai.usage.text.*` 等）时，其合计**应当**与总量字段一致。
- 缓存相关用量使用 `gen_ai.usage.cache_read.input_tokens` 与 `gen_ai.usage.cache_write.input_tokens`。
- 推理模型的思维链用量使用 `gen_ai.usage.reasoning.output_tokens`。

**【本地收紧】采样参数记录要求**：T1/T2 服务**必须**记录 `gen_ai.request.temperature`、`gen_ai.request.top_p`、`gen_ai.request.max_tokens` 中实际传入请求的那些值。这些字段是问题复现的必要条件。

**可选（`Opt-In`，默认关闭）**：`gen_ai.system_instructions`、`gen_ai.input.messages`、`gen_ai.output.messages`、`gen_ai.tool.definitions`、`gen_ai.prompt.variable`。详见第 8 章。

#### 5.3.2 其他模型侧操作

| 操作 | 关键属性 |
| --- | --- |
| 嵌入 `embeddings` | `gen_ai.request.model`、`gen_ai.embeddings.dimension.count`、`gen_ai.request.encoding_formats` |
| 检索 `retrieval` | `gen_ai.data_source.id`、`gen_ai.retrieval.top_k`、`gen_ai.retrieval.query.text`（内容，见第 8 章）、`gen_ai.retrieval.documents`（内容，见第 8 章） |
| 记忆 `memory` | 操作名区分 store 生命周期与记录操作；`gen_ai.memory.store.id`、`gen_ai.memory.record.id`、`gen_ai.memory.record.count`、`gen_ai.memory.query.text`、`gen_ai.memory.records` |
| 响应取回 `fetch_response` | `gen_ai.response.id`、`gen_ai.response.status`、`gen_ai.request.stream_cursor`；**必须不**上报 token 用量 |

**记忆操作名选择规则（`必须`）**：

| 场景 | 操作名 |
| --- | --- |
| 调用方请求**创建**新记录 | `create_memory` |
| 调用方请求**修改已知存在**的记录 | `update_memory` |
| 公共 API 可能创建、更新或合并，调用方无法选择 | `upsert_memory` |
| 查询 | `search_memory` |
| 删除指定记录 | `delete_memory` |
| 清空/删除存储 | `delete_memory_store` |

### 5.4 Agent 侧 span

| Span | 关键属性 | 备注 |
| --- | --- | --- |
| `create_agent` | `gen_ai.agent.id`、`gen_ai.agent.name`、`gen_ai.agent.description` | `gen_ai.agent.id` **必须**是供应商分配的稳定 ID（如 Bedrock ARN）。**必须不**记录内存实例 ID |
| `invoke_agent`（client） | agent 三件套 + `provider.name` + 模型字段 | 跨进程调用 |
| `invoke_agent`（internal） | 见下 | 进程内框架调用 |
| `invoke_workflow` | `gen_ai.workflow.name`、`gen_ai.conversation.id` | 工作流名**必须**是稳定的低基数标识，**必须不**包含参数值 |
| `plan` | `gen_ai.agent.name` | 规划与任务分解阶段 |

**`invoke_agent`（internal）的差异（`必须`遵守）**：
- **不要求** `gen_ai.provider.name`
- **必须不**记录 `gen_ai.agent.version`
- **必须不**记录缓存 token 明细（`gen_ai.usage.cache_*.input_tokens`）

**原因**：internal span 通常横跨多次不同模型的推理调用，聚合后的缓存与版本信息会产生误导。缓存指标**必须**从 `gen_ai.inference.client` 层聚合。

### 5.5 工具执行 span

**必须**：`gen_ai.operation.name`（`execute_tool`）、`gen_ai.tool.name`

**条件必须/推荐**：`error.type`、`gen_ai.agent.name`、`gen_ai.conversation.id`、`gen_ai.tool.call.id`、`gen_ai.tool.description`、`gen_ai.tool.type`

**可选（`Opt-In`）**：`gen_ai.tool.call.arguments`、`gen_ai.tool.call.result`

**【本地收紧】工具埋点纪律：**
- 每个 agent 可调用的工具**必须**有工具 span；自研工具由应用代码手工埋点。
- `gen_ai.tool.name` **必须**是稳定的工具标识，**必须不**包含参数。
- MCP 工具的 `gen_ai.tool.description` 与 `gen_ai.tool.definitions` 被上游标注为可能含敏感信息，采集前**必须**评估是否泄露内部系统结构。

---

## 6. 标识与关联

### 6.1 Agent 三件套

T1/T2 服务**必须**提供：

| 属性 | 要求 |
| --- | --- |
| `gen_ai.agent.name` | 人类可读名，稳定，同一 agent 不得随实例变化 |
| `gen_ai.agent.id` | 托管 agent 用供应商稳定 ID；自研 agent **应当**用服务注册中心分配的稳定 ID |
| `gen_ai.agent.version` | **必须**与发布版本联动（镜像 tag / 发布单号），用于"哪次发布引入了退化"的二分定位 |

**`gen_ai.agent.version` 与发布联动是本规范最重要的运维要求之一。** 版本号不随发布变化，等于放弃了按版本回滚与对比的能力。

### 6.2 会话标识 `gen_ai.conversation.id`

规则（`必须`遵守）：

1. **仅当**被埋点的库或应用确实持有一个会话标识时才写入。来源包括：框架的会话/线程管理（如 session_id、chat store）、供应商侧会话对象（如 thread、agent session）。
2. 无法获得真实会话标识时，**必须不**写入该属性。**禁止**用新生成的 UUID、trace id 或内容哈希兜底。
3. 应用层**可以**通过 OTel context 或库特有机制注入会话 ID —— 这是推荐做法，让多轮对话可跨服务聚合。

**原因**：用生成值兜底会使"同一会话"的聚合结果完全失真，且让基于会话的用户行为分析不可用。宁缺毋滥。

### 6.3 调用与响应标识

| 属性 | 用途 |
| --- | --- |
| `gen_ai.tool.call.id` | 关联模型返回的 tool_call 与工具执行 span |
| `gen_ai.response.id` | 关联评测事件与对应响应；响应取回操作的主键 |
| `gen_ai.request.previous_response.id` | 多轮/续写场景中引用上一条响应 |
| `gen_ai.request.stream_cursor` | 流式响应续传位置 |

### 6.4 上下文传播

| 场景 | 要求 |
| --- | --- |
| 多 agent 协作 | **必须**用 `invoke_agent` span 的父子关系表达调用拓扑，**必须不**把多 agent 展平为平级 span |
| 跨进程 / 跨服务 | **必须**透传 W3C trace context（或等价传播机制） |
| 跨 MCP | **必须**透传 trace context，使 MCP client 与 server span 归属同一 trace |
| 异步/后台任务 | **必须**在任务入队时序列化 context，出队时恢复 |
| 子 agent 预算 | 子 agent 的成本**应当**能沿 span 关系归因到父任务 |

---
## 7. 属性规范

### 7.1 命名空间总表

**任何团队必须不新增命名空间。** 下表为可使用的全集。

| 命名空间 | 用途 | 典型键 |
| --- | --- | --- |
| `gen_ai.operation.name` | 操作判别符 | 见附录 A.1 |
| `gen_ai.provider.name` | 供应商判别符 | 见附录 A.2 |
| `gen_ai.request.*` | 请求参数 | `model`、`temperature`、`top_p`、`top_k`、`max_tokens`、`stop_sequences`、`choice.count`、`seed`、`stream`、`reasoning.level`、`previous_response.id`、`encoding_formats` |
| `gen_ai.response.*` | 响应元数据 | `id`、`model`、`finish_reasons`、`status`、`time_to_first_chunk` |
| `gen_ai.usage.*` | token 用量 | 总量、按模态、缓存读写、推理用量 |
| `gen_ai.agent.*` | Agent 身份 | `id`、`name`、`description`、`version` |
| `gen_ai.conversation.*` | 会话 | `id`、`compacted` |
| `gen_ai.tool.*` | 工具 | `name`、`type`、`description`、`definitions`、`call.id`、`call.arguments`、`call.result` |
| `gen_ai.retrieval.*` | 检索 | `top_k`、`query.text`、`documents` |
| `gen_ai.memory.*` | 记忆 | `store.id`、`record.id`、`record.count`、`query.text`、`records` |
| `gen_ai.embeddings.*` | 嵌入 | `dimension.count` |
| `gen_ai.prompt.*` | Prompt 模板治理 | `name`、`version`、`variable` |
| `gen_ai.evaluation.*` | 评测 | `name`、`score.value`、`score.label`、`explanation` |
| `gen_ai.system_instructions` | 系统指令（内容） | 见第 8 章 |
| `gen_ai.input.messages` / `gen_ai.output.messages` | 消息（内容） | 见第 8 章 |
| `gen_ai.data_source.id` | 数据源标识 | 检索的数据源 |
| `gen_ai.workflow.name` | 工作流名 | — |
| `gen_ai.token.type` | 指标标签 | `input` / `output` |
| `gen_ai.output.type` | 输出类型 | `text` / `json` / `image` / `speech` |
| `error.type` | 错误分类 | 低基数错误标识 |
| `server.address` / `server.port` | 网络端点 | 标准 OTel 属性 |

### 7.2 采样可见性矩阵

**【本地收紧】** 以下属性**必须**在 span 创建时提供，否则尾部采样无法基于它们决策。这是 T1/T2 的强制要求。

| 属性 | 适用 span |
| --- | --- |
| `gen_ai.operation.name` | 全部 |
| `gen_ai.provider.name` | 全部（internal agent span 除外） |
| `gen_ai.request.model` | 模型侧 |
| `gen_ai.agent.name` | agent 侧、工具、规划 |
| `gen_ai.tool.name` | 工具 |
| `server.address` / `server.port` | 网络可观测时 |

### 7.3 枚举值纪律

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-7.3.1 | 上游已定义的枚举值**必须**优先使用，不得用本地同义词替换 | 必须 |
| GEN-7.3.2 | 上游未覆盖的取值**可以**自定义，但**必须**登记到附录 A 的本地扩展表并经平台评审 | 必须 |
| GEN-7.3.3 | `gen_ai.provider.name` 使用代理或托管平台时，按 instrumentation 的最佳认知设置，可与实际上游不同 | 应当 |
| GEN-7.3.4 | `gen_ai.operation.name` 在特定系统使用不同名称时，**必须**在文档中登记后再使用 | 必须 |

### 7.4 基数控制

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-7.4.1 | span 名与指标标签**必须不**包含无界取值 | 必须 |
| GEN-7.4.2 | `gen_ai.tool.name`、`gen_ai.agent.name`、`gen_ai.workflow.name`、`gen_ai.data_source.id` **应当**控制在每服务数十个量级 | 应当 |
| GEN-7.4.3 | 高基数业务标识（租户、用户、任务）**应当**放在受控的归因标签或资源属性上，而非 span 名 | 应当 |
| GEN-7.4.4 | `error.type` **必须**保持低基数 | 必须 |

---

## 8. 敏感内容与合规

### 8.1 默认禁止

模型系统指令、用户输入、模型输出、工具定义与工具调用参数/结果，**默认必须不采集**。

**原因**：这些内容体积大、含 PII 与商业机密。遥测后端通常不具备与业务数据同等级的访问控制，默认采集等于把业务数据副本扩散到一个治理更弱的系统。

### 8.2 三种模式

服务**必须**明确选择其一，并记录在服务的 `observability.md` 中：

| 模式 | 行为 | 适用 |
| --- | --- | --- |
| **A. 仅元数据（默认）** | 不记录任何内容属性 | 所有生产环境默认 |
| **B. 属性内联** | 在 span 上记录内容属性 | 预发、或合规评审通过且遥测存储满足要求的场景 |
| **C. 外存 + 引用** | 内容写入可独立授权的存储，span 上只留引用 | **生产推荐** |

【本地收紧】生产环境（T1/T2）**必须不**使用模式 B，除非完成合规评审并登记例外。

### 8.3 模式 B 的附加要求

| 编号 | 要求 | 级别 |
| --- | --- | --- |
| GEN-8.3.1 | 内容结构**必须**符合上游 JSON schema（`gen-ai-input-messages.json` 等） | 必须 |
| GEN-8.3.2 | 记录在 span 上时，**应当**使用结构化形式；不支持结构化时才退化为 JSON 字符串 | 应当 |
| GEN-8.3.3 | 记录在事件上时，**必须**使用结构化形式 | 必须 |
| GEN-8.3.4 | **必须**在采集前完成 PII 脱敏，或确保遥测存储本身满足数据保留与访问要求 | 必须 |
| GEN-8.3.5 | **必须**设置内容长度上限，防止超出后端 envelope 限制 | 必须 |
| GEN-8.3.6 | `gen_ai.system_instructions` **应当**只使用 text 类型 part | 应当 |

### 8.4 模式 C 的附加要求

| 编号 | 要求 | 级别 |
| --- | --- | --- |
| GEN-8.4.1 | 内容存储**必须**支持独立的访问控制与审计 | 必须 |
| GEN-8.4.2 | span 上的引用**必须**能在内容被删除后表现为"已删除"，而非悬挂引用 | 必须 |
| GEN-8.4.3 | 内容**必须**设置 TTL，且 TTL **应当**短于遥测数据的保留期 | 必须 |
| GEN-8.4.4 | 内容存储的删除请求**必须**可追溯 | 应当 |

### 8.5 敏感属性清单（采集前需评审）

| 属性 | 敏感原因 |
| --- | --- |
| `gen_ai.system_instructions` | 暴露系统提示词与业务规则 |
| `gen_ai.input.messages` | 用户输入，含 PII |
| `gen_ai.output.messages` | 模型输出，可能复述 PII |
| `gen_ai.tool.definitions` | 暴露内部系统与 API 结构 |
| `gen_ai.tool.description` | 同上 |
| `gen_ai.tool.call.arguments` | 业务参数，可能含凭据 |
| `gen_ai.tool.call.result` | 业务数据 |
| `gen_ai.retrieval.query.text` | 用户查询原文 |
| `gen_ai.retrieval.documents` | 内部文档内容 |
| `gen_ai.memory.query.text` | 用户记忆查询 |
| `gen_ai.memory.records` | 用户记忆内容 |
| `gen_ai.prompt.variable` | Prompt 模板变量，可能含用户数据 |
| `exception.message` | 可能包含请求内容或凭据 |

---

## 9. 指标规范

### 9.1 指标清单

| 指标 | 类型 | 单位 | 级别 |
| --- | --- | --- | --- |
| `gen_ai.client.token.usage` | Histogram | `{token}` | 必须 |
| `gen_ai.client.operation.duration` | Histogram | `s` | 必须 |
| `gen_ai.client.operation.time_to_first_chunk` | Histogram | `s` | 必须（流式） |
| `gen_ai.client.operation.time_per_output_chunk` | Histogram | `s` | 应当（流式） |
| `gen_ai.server.request.duration` | Histogram | `s` | 自托管模型服务必须 |
| `gen_ai.server.time_to_first_token` | Histogram | `s` | 自托管模型服务应当 |
| `gen_ai.server.time_per_output_token` | Histogram | `s` | 自托管模型服务应当 |
| `gen_ai.invoke_workflow.duration` | Histogram | `s` | 应当 |
| `gen_ai.invoke_agent.duration` | Histogram | `s` | 必须 |
| `gen_ai.invoke_agent.inference_calls` | Counter | `{call}` | 必须 |
| `gen_ai.invoke_agent.tool_calls` | Counter | `{call}` | 必须 |
| `gen_ai.execute_tool.duration` | Histogram | `s` | 必须 |

### 9.2 分桶要求

**【本地收紧】必须**使用上游指定分桶，不得自定义，否则跨服务聚合失去意义。

| 指标组 | ExplicitBucketBoundaries |
| --- | --- |
| `gen_ai.client.token.usage` | `1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 4194304, 16777216, 67108864` |
| client 操作时长类（duration / TTFC / time per chunk） | `0.01, 0.02, 0.04, 0.08, 0.16, 0.32, 0.64, 1.28, 2.56, 5.12, 10.24, 20.48, 40.96, 81.92` |
| 工作流 / agent / 工具 时长类 | `1, 5, 10, 30, 60, 120, 300, 600, 1800, 3600, 7200` |

### 9.3 标签要求

`gen_ai.client.token.usage` 的**必须**标签：

| 标签 | 取值 |
| --- | --- |
| `gen_ai.operation.name` | 操作名 |
| `gen_ai.provider.name` | 供应商 |
| `gen_ai.token.type` | `input` / `output` |

**应当**附加：`gen_ai.request.model`、`gen_ai.response.model`、`server.address`、`server.port`。

**【本地收紧】业务归因标签**：T1/T2 服务**应当**在指标上附加部门/业务域标签，使成本可按组织维度切分。标签**必须**来自受控字典，**必须不**使用用户或任务级高基数取值。

### 9.4 用量上报规则

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-9.4.1 | 计费 token 与消耗 token 并存时，**必须**上报计费口径 | 必须 |
| GEN-9.4.2 | 只有确实获得计数时才上报；无法高效获取输入/输出 token 数时，**可以**提供离线计数开关，否则**必须不**上报该指标 | 必须 |
| GEN-9.4.3 | 流式响应中若供应商已返回用量，**必须**使用该值 | 必须 |
| GEN-9.4.4 | `gen_ai.invoke_agent.inference_calls` 与 `gen_ai.invoke_agent.tool_calls` **必须**按单次 agent 调用聚合，而非全局累计 | 必须 |

**运维提示**：`inference_calls` / `tool_calls` 是发现 **agent 绕圈（loop）** 最早、最可靠的信号。建议建立基线并对此设置告警——工具调用次数相对基线的异常抬升，通常早于用户投诉出现。

### 9.5 归因要求

**【本地收紧】** T1/T2 服务**必须**能回答问题："过去 24 小时内，某部门/某 agent 的成本是多少？"

实现路径：以 trace 为归因单元，由 inference span 上的 token 用量 × 模型单价折算，沿 `gen_ai.agent.name` / `gen_ai.agent.version` / 部门标签聚合。子 agent 的成本**必须**能归因到父任务。

---
## 10. 事件与异常

### 10.1 `gen_ai.evaluation.result`（在线评测）

**用途**：把评测结果作为**运行期事件**写入 trace，使评测从"离线跑分"变为"生产持续度量"。

**要求**：

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-10.1.1 | 事件**应当**挂载在**被评测的那个 span** 之下（如 `execute_tool`、`plan`、`retrieval`、推理 span），而不是统一挂到根 span | 应当 |
| GEN-10.1.2 | 无法挂载到 span 时，**必须**设置 `gen_ai.response.id` 以建立关联 | 必须 |
| GEN-10.1.3 | **必须**提供 `gen_ai.evaluation.name` | 必须 |
| GEN-10.1.4 | **应当**提供 `gen_ai.evaluation.score.value` 或 `gen_ai.evaluation.score.label` 至少之一 | 应当 |
| GEN-10.1.5 | `gen_ai.evaluation.score.label` **必须**低基数，且取值集合**必须**在评测系统文档中登记 | 必须 |
| GEN-10.1.6 | 评测器自身失败时**必须**设置 `error.type`，且**必须不**伪造分数 | 必须 |

**为什么挂载位置重要**：agent 的错误常常不在最终答复，而在中间步骤（选错工具、参数错、检索到脏数据、多轮后忘记约束）。只评测最终答复会漏掉大部分失效模式。

### 10.2 `gen_ai.client.inference.operation.details`（推理明细）

**用途**：把一次推理的完整细节（请求参数、用量、可选内容）作为事件记录。适合"不希望 span 承载重属性，但仍需可查询"的场景。

**要求**：

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-10.2.1 | 该事件**必须**与对应的推理 span 处于同一 trace | 必须 |
| GEN-10.2.2 | 事件中若包含内容字段，**必须**遵守第 8 章的对应模式 | 必须 |
| GEN-10.2.3 | 上报该事件时**必须不**与 span 上的同名属性冲突（取值应一致） | 必须 |

### 10.3 `gen_ai.client.operation.exception`（异常）

**用途**：记录 GenAI 客户端操作中的异常（API 错误、限流、模型错误、超时等）。

**属性**：`exception.type`、`exception.message`、`exception.stacktrace`（三者**可以**携带对应 span 的属性，由实现配置）

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-10.3.1 | 严重级别**必须**设为 WARN（severity number 13） | 必须 |
| GEN-10.3.2 | `exception.type` 为无意义包装类型时**可以**使用内层异常类型 | 可以 |
| GEN-10.3.3 | `exception.message` 可能含敏感信息，**应当**在采集前评估 | 应当 |

---

## 11. MCP 扩展

服务使用 MCP（Model Context Protocol）**必须**遵守本节。

### 11.1 Span

| 侧 | Span 名 | Kind |
| --- | --- | --- |
| Client | `{mcp.method.name} {target}`；无低基数 target 时用 `{mcp.method.name}` | `CLIENT` |
| Server | 同上 | `SERVER` |

**上下文传播**：MCP client 与 server span **必须**归属同一 trace（依赖 trace context 透传）。

### 11.2 指标

| 指标 | 级别 |
| --- | --- |
| `mcp.client.operation.duration` | 必须 |
| `mcp.server.operation.duration` | 必须（自建 MCP server） |
| `mcp.client.session.duration` | 应当 |
| `mcp.server.session.duration` | 应当（自建 MCP server） |

### 11.3 传输层记录

stdio 与 Streamable HTTP 传输**应当**按上游文档记录，便于区分"协议层慢"与"工具本身慢"。

### 11.4 工具参数与结果

**【本地收紧】** MCP server span 上的 `gen_ai.tool.call.arguments` 与 `gen_ai.tool.call.result` 为 `Opt-In`。采集前**必须**评估第三方 MCP server 的可信度——这两个字段是 prompt injection 借工具外泄数据的主要载体。

---

## 12. 厂商扩展

`gen_ai.provider.name` 是**判别符**，决定哪些厂商专属属性可以使用。

| 编号 | 规则 | 级别 |
| --- | --- | --- |
| GEN-12.1 | 设置为某厂商值时，**应当**同时使用该厂商命名空间的属性（如 `aws.bedrock.*`、`openai.*`） | 应当 |
| GEN-12.2 | **必须不**混用不同厂商的属性（例如 `provider.name = aws.bedrock` 却携带 `openai.*` 属性） | 必须 |
| GEN-12.3 | 使用代理或托管平台时，`gen_ai.provider.name` **应当**反映 instrumentation 的最佳认知，可与实际上游不同 | 应当 |

上游已提供厂商专属约定的系统：**Anthropic**、**AWS Bedrock**、**Azure AI Inference**、**OpenAI**。

---
## 13. 合规验收

### 13.1 自动化校验

| 手段 | 说明 | 级别 |
| --- | --- | --- |
| Schema 校验 | 用上游 registry 模型 + OTel Weaver 校验产出的遥测是否符合约定 | 应当 |
| 冒烟 trace 断言 | 在 CI 中对固定输入产生 trace，断言必需 span 与属性存在 | 必须 |
| 漂移检测 | 定期比对上游规范快照，发现破坏性变更时开单 | 应当 |
| 命名合规检查 | 静态扫描代码中是否出现裸 `gen_ai.` 字面量（应全部走常量模块） | 应当 |

**冒烟断言的最小集合**（T1/T2 必须）：

1. 存在 `invoke_agent` span，且携带 agent 三件套。
2. 存在至少一个推理 span，且携带 `gen_ai.usage.input_tokens` 与 `gen_ai.usage.output_tokens`。
3. 采样属性在 span 创建时可见（可用 span 起始属性的快照断言）。
4. 工具调用场景下存在对应的 `execute_tool` span。
5. 失败场景下 `error.type` 与异常事件同时存在。
6. 默认配置下 trace 中**不出现**任何内容属性。

### 13.2 上线前检查清单

详见附录 C。

### 13.3 例外流程

需要偏离本规范时，**必须**：

1. 在服务的 `observability.md` 中记录：偏离条目、理由、补偿措施、失效条件。
2. 由平台工程评审通过。
3. 设定复审日期（不超过 6 个月）。

未登记的偏离视为不合规。

---

## 14. 版本演进策略

### 14.1 上游变更响应

| 上游变更类型 | 响应要求 | 时限 |
| --- | --- | --- |
| 破坏性变更（重命名、删除、类型变更） | 更新 `otel-genai` 封装包 + 更新附录 D 台账 + 通知使用方 | 5 个工作日内 |
| 新增操作或属性 | 评估是否纳入本地必需集，更新本规范 | 下一个评审周期 |
| 澄清类变更 | 更新台账，必要时补充本地说明 | 下一个评审周期 |

### 14.2 本规范的版本

- 修订号（v0.1 → v0.2）：向后兼容的补充与澄清。
- 主版本号（v0.x → v1.0）：引入强制要求或破坏性变更。需给出迁移窗口与双写过渡期。

### 14.3 冻结条件

本规范从 v0.1 升级到 v1.0 的前提：

1. 上游 GenAI 约定中本规范所依赖的核心条目进入 `Stable`，**或**已稳定跨越两个上游发布周期无破坏性变更。
2. 至少两个不同框架的埋点在内部通过 13.1 的全部自动化校验。
3. 成本归因链路（9.5）端到端跑通并产出真实报表。

---

## 附录 A：枚举值全集

### A.1 `gen_ai.operation.name` 白名单

**模型侧**：`chat`、`text_completion`、`generate_content`、`embeddings`、`retrieval`、`fetch_response`

**记忆侧**：`create_memory_store`、`delete_memory_store`、`create_memory`、`update_memory`、`upsert_memory`、`search_memory`、`delete_memory`

**Agent 侧**：`create_agent`、`invoke_agent`、`invoke_workflow`、`plan`

**工具**：`execute_tool`

使用规则：若某取值适用则**必须**使用；本地扩展取值**必须**先在附录 A.6 登记。

### A.2 `gen_ai.provider.name` 白名单

`anthropic`、`aws.bedrock`、`azure.ai.inference`、`azure.ai.openai`、`cohere`、`deepseek`、`gcp.gemini`、`gcp.gen_ai`、`gcp.vertex_ai`、`groq`、`ibm.watsonx.ai`、`mistral_ai`、`moonshot_ai`、`openai`、`perplexity`、`x_ai`

**辨析**：`gcp.gemini` 指 `generativelanguage.googleapis.com` 端点（AI Studio API）；`gcp.vertex_ai` 指 Vertex AI；`gcp.gen_ai` 指任意 Google 生成式 AI 端点。

### A.3 `gen_ai.tool.type`

`function`、`extension`、`datastore`

### A.4 `gen_ai.output.type`

`text`、`json`、`image`、`speech`

### A.5 `gen_ai.token.type`

`input`、`output`

### A.6 本地扩展登记表

| 取值 | 所属属性 | 提出方 | 批准日期 | 理由 |
| --- | --- | --- | --- | --- |
| （暂无） | — | — | — | — |

### A.7 `error.type`

优先使用：供应商错误码 → 客户端库错误码 → 异常类名 → `_OTHER`。

**必须**在同一服务内保持一致，且**必须**在服务文档中列出可能取值清单。

---

## 附录 B：参考实现与资料

### B.1 上游规范快照（本仓库）

| 文件 | 内容 |
| --- | --- |
| `research/otel/docs__gen-ai__README.md` | 信号总览 |
| `research/otel/docs__gen-ai__gen-ai-spans.md` | 模型侧 span 全量定义 |
| `research/otel/docs__gen-ai__gen-ai-agent-spans.md` | Agent 侧 span 定义 |
| `research/otel/docs__gen-ai__gen-ai-metrics.md` | 指标定义与分桶 |
| `research/otel/docs__gen-ai__gen-ai-events.md` | 事件定义 |
| `research/otel/docs__gen-ai__gen-ai-exceptions.md` | 异常定义 |
| `research/otel/docs__gen-ai__mcp.md` | MCP 约定 |
| `research/otel/docs__gen-ai__openai.md` 等 | 厂商专属约定 |
| `research/otel/docs__registry__attributes__gen-ai.md` | 属性总表（代码生成输入） |
| `research/otel/reference__README.md` | 各语言/框架一致性覆盖报告 |

### B.2 已验证的参考实现（可抄写）

上游 `reference/scenarios/` 提供了真实库 + 本地 mock server 的一致性验证实现，覆盖：

- **Agent 框架**：LangChain、LangGraph、LlamaIndex、CrewAI、AutoGen、Microsoft Agent Framework、Google ADK、OpenAI Agents、OpenAI Assistants、Pydantic AI、Claude Agent SDK、DSPy、Haystack
- **模型客户端**：OpenAI、Anthropic、AWS Bedrock、Azure OpenAI、Azure AI Inference、Google GenAI、Vertex AI、Cohere、Groq、Mistral AI、LiteLLM
- **服务端 agent**：AWS Bedrock Agent / AgentCore、Azure AI Foundry
- **评测**：Azure AI Evaluation、DeepEval、DSPy

**用法**：在选型或验收某个框架的埋点时，先查其覆盖报告，确认它实际产出了哪些 span/指标/事件，而不要依赖框架文档的宣称。

### B.3 埋点层组件选型

| 组件 | 定位 |
| --- | --- |
| OpenInference / OpenLLMetry / OpenLIT | 把各框架调用转换为标准 GenAI 遥测，可与任意后端组合 |

---

## 附录 C：上线检查清单

复制到发布单中逐项确认。

**骨架**

- [ ] 推理操作已产生 span，名称符合 `{operation} {model}` 格式
- [ ] Agent 调用已产生 `invoke_agent` span，跨进程场景为 client、进程内为 internal
- [ ] 多 agent 场景用父子关系表达，未展平
- [ ] 所有 span 的耗时覆盖完整逻辑操作**包含重试**

**身份与关联**

- [ ] `gen_ai.agent.id` / `gen_ai.agent.name` / `gen_ai.agent.version` 三件套齐全
- [ ] `gen_ai.agent.version` 与本次发布版本联动
- [ ] `gen_ai.conversation.id` 来自真实会话标识，未使用 UUID/trace id/哈希兜底
- [ ] 跨服务与 MCP 调用 trace context 已透传

**属性**

- [ ] 采样相关属性在 span 创建时提供
- [ ] `gen_ai.usage.input_tokens` / `output_tokens` 已上报，且为计费口径
- [ ] 请求采样参数（temperature / top_p / max_tokens）按实际传入记录
- [ ] `error.type` 为低基数，且失败时同时产生异常事件
- [ ] 未在 `fetch_response` 操作上上报 token 用量
- [ ] 代码中无裸 `gen_ai.` 字面量，全部走平台常量模块

**内容与合规**

- [ ] 已明确选择模式 A / B / C 并记录在 `observability.md`
- [ ] 生产环境未使用模式 B（除非已登记例外）
- [ ] 内容采集开关默认关闭
- [ ] 若开启采集，已确认脱敏、长度上限、TTL 与访问控制

**指标**

- [ ] 指标使用上游规定的分桶
- [ ] `gen_ai.client.token.usage` 携带 `gen_ai.token.type` 标签
- [ ] `gen_ai.invoke_agent.inference_calls` / `tool_calls` 已启用并建立基线告警
- [ ] 成本可按部门 / agent / 版本归因

**验收**

- [ ] CI 冒烟 trace 断言通过
- [ ] Weaver schema 校验通过
- [ ] 已在预发环境人工检视一条完整 trace

---

## 附录 D：上游破坏性变更台账

记录本规范制定时已知的上游破坏性变更，用于评估存量埋点受影响范围。

| 变更 | 影响 | 本地适配状态 |
| --- | --- | --- |
| `gen_ai.usage.cache_creation.input_tokens` → `gen_ai.usage.cache_write.input_tokens` | 缓存写入用量的键名变更 | 封装包已按新名实现 |
| 新增按模态用量 `gen_ai.usage.{text,image,audio}.*` | 用量可细分到模态 | 可选启用 |
| 缓存明细从 internal `invoke_agent` span 移除 | 该 span 不再记录 `cache_read` / `cache_write` | 已按新规则实现；缓存指标从推理层聚合 |
| `gen_ai.request.top_k` 类型 `double` → `int`，收窄为解码参数 | 检索场景不再使用该键 | 检索改用 `gen_ai.retrieval.top_k` |
| `gen_ai.output.messages[].finish_reason` 废弃 | 统一使用 `gen_ai.response.finish_reasons` | 已切换；缺失时填 `error` |
| internal `invoke_agent` span 移除 `gen_ai.provider.name` 必填 | 该 span 可省略 provider | 已按新规则实现 |
| internal `invoke_agent` span 移除 `gen_ai.agent.version` | 版本仅记录在 client span 与 create_agent | 已按新规则实现 |
| `gen_ai.system_instructions` 限定为 text part | 不再支持非文本系统指令 part | 已按新规则实现 |

> 台账**必须**在每次上游破坏性变更后更新。字段格式：变更内容 / 影响面 / 本地适配状态 / 适配版本 / 完成日期。

---

**文档结束**