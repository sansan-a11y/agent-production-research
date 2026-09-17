$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dir = 'research/pages'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$repos = @(
 'langfuse/langfuse','Arize-ai/phoenix','Arize-ai/openinference','traceloop/openllmetry',
 'comet-ml/opik','confident-ai/deepeval','explodinggradients/ragas','promptfoo/promptfoo',
 'UKGovernmentBEIS/inspect_ai','EleutherAI/lm-evaluation-harness','openai/evals','mlflow/mlflow',
 'BerriAI/litellm','Portkey-AI/gateway','envoyproxy/ai-gateway','Kong/kong','agentgateway/agentgateway',
 'vllm-project/semantic-router','IBM/mcp-context-forge','tensorzero/tensorzero',
 'langchain-ai/langgraph','langchain-ai/deepagents','openai/openai-agents-python','google/adk-python',
 'microsoft/autogen','crewAIInc/crewAI','agno-agi/agno','microsoft/agent-framework','temporalio/temporal',
 'inngest/inngest','restatedev/restate','kagent-dev/kagent','kubernetes-sigs/agent-sandbox',
 'run-llama/llama_index','microsoft/semantic-kernel','e2b-dev/E2B',
 'mem0ai/mem0','getzep/zep','letta-ai/letta','langchain-ai/langmem',
 'modelcontextprotocol/modelcontextprotocol','a2aproject/A2A','modelcontextprotocol/registry',
 'NVIDIA/NeMo-Guardrails','guardrails-ai/guardrails','meta-llama/PurpleLlama','invariantlabs-ai/invariant',
 'vllm-project/vllm','ray-project/ray','open-feature/spec','Agenta-AI/agenta','stanfordnlp/dspy',
 'google/adk-java','anthropics/anthropic-cookbook','langchain-ai/langchain','dapr/dapr-agents'
)

$names = @('README.md','readme.md','README.rst','README.MD','docs/README.md')
$ok = 0; $fail = @()
foreach ($r in $repos) {
  $slug = ($r -replace '/','__')
  $dest = Join-Path $dir "$slug.md"
  if (Test-Path $dest) { continue }
  $got = $false
  foreach ($b in @('HEAD','main','master')) {
    foreach ($n in $names) {
      $u = "https://raw.githubusercontent.com/$r/$b/$n"
      try {
        $resp = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 25
        if ($resp.StatusCode -eq 200 -and $resp.Content.Length -gt 200) {
          [IO.File]::WriteAllText((Resolve-Path -LiteralPath '.').Path + '\' + $dest, $resp.Content)
          $got = $true; $ok++; break
        }
      } catch { }
    }
    if ($got) { break }
  }
  if (-not $got) { $fail += $r }
}
"READMEs ok=$ok fail=$($fail.Count)"
$fail -join ', '
