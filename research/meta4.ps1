$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$repos = @(
  'langchain-ai/langchain','langchain-ai/langgraph','langchain-ai/deepagents','openai/openai-agents-python',
  'google/adk-python','microsoft/agent-framework','microsoft/semantic-kernel','strands-agents/sdk-python',
  'crewAIInc/crewAI','agno-agi/agno','pydantic/pydantic-ai','mastra-ai/mastra',
  'NVIDIA/NeMo-Guardrails','guardrails-ai/guardrails','meta-llama/PurpleLlama','protectai/llm-guard',
  'vijil/vijil','QwenLM/Qwen3Guard','ibm-granite/granite-guardian','NVIDIA/garak','Azure/PyRIT',
  'open-policy-agent/opa','cedar-policy/cedar','openfga/openfga','cerbos/cerbos','permitio/permit',
  'stacklok/toolhive','obot-platform/obot','IBM/mcp-context-forge','snyk/mcp-scan','agentgateway/agentgateway',
  'langfuse/langfuse','langchain-ai/langsmith-sdk','Arize-ai/phoenix','comet-ml/opik','wandb/weave',
  'braintrustdata/braintrust-sdk','lmnr-ai/lmnr','truera/trulens','evidentlyai/evidently','Giskard-AI/giskard-oss',
  'galileo-ai/galileo-python','promptfoo/promptfoo','confident-ai/deepeval','UKGovernmentBEIS/inspect_ai',
  'vectara/hallucination-leaderboard','potsawee/selfcheckgpt','lianhua-zhao/MiniCheck','amazon-science/refchecker',
  'sierra-research/tau2-bench','princeton-pli/hal-harness','metauto-ai/agent-as-a-judge','thu-coai/Agent-SafetyBench',
  'ryoungj/ToolEmu','ethz-spylab/agentdojo','kubernetes-sigs/agent-sandbox','e2b-dev/E2B','abshkbh/arrakis',
  'temporalio/temporal','restatedev/restate','dapr/dapr-agents','inngest/inngest','hatchet-dev/hatchet','dbos-inc/dbos-transact-py'
)
$res = foreach ($r in $repos) {
  $s='?'; $v='?'
  try { $s = (Invoke-RestMethod -Uri "https://img.shields.io/github/stars/$r.json" -TimeoutSec 25).value } catch {}
  try { $v = (Invoke-RestMethod -Uri "https://img.shields.io/github/v/release/$r.json" -TimeoutSec 25).value } catch {}
  "{0,-46} stars={1,-8} release={2}" -f $r, $s, $v
}
$res | Set-Content -Encoding UTF8 research/meta4.txt
"shields done: $($res.Count) repos"
