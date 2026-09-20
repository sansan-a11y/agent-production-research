$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
$repos = @(
  # A. 运行时 hook / middleware（框架侧注入点）
  'langchain-ai/langchain','langchain-ai/langgraph','langchain-ai/deepagents','openai/openai-agents-python',
  'openai/openai-agents-js','google/adk-python','google/adk-java','microsoft/agent-framework',
  'microsoft/semantic-kernel','strands-agents/sdk-python','crewAIInc/crewAI','agno-agi/agno',
  'pydantic/pydantic-ai','mastra-ai/mastra','run-llama/llama_index','livekit/agents','pipecat-ai/pipecat',
  # B. 护栏 / 审核模型 / 检查器
  'NVIDIA/NeMo-Guardrails','guardrails-ai/guardrails','meta-llama/PurpleLlama','protectai/llm-guard',
  'vijil/vijil','QwenLM/Qwen3Guard','ibm-granite/granite-guardian','NVIDIA/garak','Azure/PyRIT',
  # C. 策略 / 工具与 MCP 治理
  'open-policy-agent/opa','cedar-policy/cedar','openfga/openfga','cerbos/cerbos','permitio/permit',
  'stacklok/toolhive','obot-platform/obot','IBM/mcp-context-forge','snyk/mcp-scan','agentgateway/agentgateway',
  'envoyproxy/ai-gateway','BerriAI/litellm','alibaba/higress',
  # D. 在线评测 / 生产轨迹监督
  'langfuse/langfuse','langchain-ai/langsmith-sdk','Arize-ai/phoenix','comet-ml/opik','wandb/weave',
  'braintrustdata/braintrust-sdk','lmnr-ai/lmnr','truera/trulens','evidentlyai/evidently','Giskard-AI/giskard-oss',
  'galileo-ai/galileo-python','promptfoo/promptfoo','confident-ai/deepeval','UKGovernmentBEIS/inspect_ai',
  # E. 幻觉 / 忠实度检查
  'vectara/hallucination-leaderboard','potsawee/selfcheckgpt','lianhua-zhao/MiniCheck','amazon-science/refchecker',
  # F. 可靠性与对抗评测基准（定期在线验证的"测试集"）
  'sierra-research/tau2-bench','sierra-research/tau-bench','princeton-pli/hal-harness','metauto-ai/agent-as-a-judge',
  'thu-coai/Agent-SafetyBench','ryoungj/ToolEmu','ethz-spylab/agentdojo','laude-institute/terminal-bench',
  'web-arena-x/webarena','THUDM/AgentBench',
  # G. 沙箱 / 持久化执行 / 人工审批
  'kubernetes-sigs/agent-sandbox','e2b-dev/E2B','abshkbh/arrakis','temporalio/temporal','restatedev/restate',
  'dapr/dapr-agents','inngest/inngest','hatchet-dev/hatchet','dbos-inc/dbos-transact-py'
)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# repo metadata snapshot (search API)  generated $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
for ($i=0; $i -lt $repos.Count; $i+=8) {
  $chunk = $repos[$i..([math]::Min($i+7,$repos.Count-1))]
  $q = (($chunk | ForEach-Object { "repo:$_" }) -join '+')
  $url = "https://api.github.com/search/repositories?q=$q&per_page=100"
  try {
    $r = Invoke-RestMethod -Uri $url -Headers $h -TimeoutSec 45
    $lines.Add("")
    $lines.Add("== batch $($i/8 + 1) : requested $($chunk.Count), returned $($r.items.Count) ==")
    foreach ($it in $r.items) {
      $lic = if ($it.license) { $it.license.spdx_id } else { 'none' }
      $desc = ($it.description -replace '\s+',' ')
      if ($desc -and $desc.Length -gt 150) { $desc = $desc.Substring(0,150) }
      $lines.Add(("{0,-44} stars={1,-7} pushed={2} lic={3,-14} :: {4}" -f $it.full_name, $it.stargazers_count, ([string]$it.pushed_at).Substring(0,10), $lic, $desc))
    }
  } catch { $lines.Add("ERR batch $($i/8 + 1): $($_.Exception.Message)") }
  Start-Sleep -Seconds 8
}
$lines | Set-Content -Encoding UTF8 research/meta3.txt
"meta3 done: $($lines.Count) lines"
