$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path research/vendor2 | Out-Null
function Grab($name, $url, $raw) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 35 -Headers @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    $t = $r.Content
    if (-not $raw) {
      $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '(?s)<nav.*?</nav>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&#39;',"'" -replace '&quot;','"' -replace '&gt;','>' -replace '&lt;','<' -replace '\s{2,}',' '
    }
    [IO.File]::WriteAllText((Join-Path (Get-Location) "research/vendor2/$name.txt"), $t)
    "ok   $name ($($t.Length) bytes)"
  } catch { "FAIL $name : $($_.Exception.Message)" }
}
# --- 运行时护栏 / 校验（厂商官方文档） ---
Grab 'claude-code-hooks'   'https://docs.claude.com/en/docs/claude-code/hooks' $false
Grab 'claude-agent-sdk'    'https://docs.claude.com/en/api/agent-sdk/overview' $false
Grab 'claude-sdk-perms'    'https://docs.claude.com/en/api/agent-sdk/permissions' $false
Grab 'aws-grounding'       'https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-contextual-grounding-check.html' $false
Grab 'aws-autoreasoning'   'https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-automated-reasoning-checks.html' $false
Grab 'aws-agentcore-policy' 'https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy.html' $false
Grab 'azure-groundedness'  'https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/groundedness' $false
Grab 'azure-taskadherence' 'https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/task-adherence' $false
Grab 'azure-contentsafety' 'https://learn.microsoft.com/en-us/azure/ai-services/content-safety/overview' $false
Grab 'vertex-checkgrounding' 'https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/check-grounding' $false
Grab 'google-modelarmor'   'https://cloud.google.com/security-command-center/docs/model-armor-overview' $false
# --- 在线评测 / 运行时监督（可观测平台文档） ---
Grab 'langsmith-onlineevals' 'https://docs.langchain.com/langsmith/online-evaluations' $false
Grab 'langsmith-automations' 'https://docs.langchain.com/langsmith/automations' $false
Grab 'langchain-middleware'  'https://docs.langchain.com/oss/python/langchain/middleware' $false
Grab 'langfuse-judge'      'https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge' $false
Grab 'langfuse-monitors'   'https://langfuse.com/docs/observability/features/monitors' $false
Grab 'datadog-llm-evals'   'https://docs.datadoghq.com/llm_observability/evaluations/' $false
Grab 'braintrust-automations' 'https://www.braintrust.dev/docs/guides/automations' $false
Grab 'weave-monitors'      'https://weave-docs.wandb.ai/guides/tools/monitors' $false
Grab 'phoenix-onlineeval'  'https://arize.com/docs/phoenix/evaluation/online-evaluation' $false
# --- 框架内置的 hook / middleware / guardrail 机制 ---
Grab 'adk-callbacks'       'https://google.github.io/adk-docs/callbacks/' $false
Grab 'sk-filters'          'https://learn.microsoft.com/en-us/semantic-kernel/concepts/enterprise-readiness/filters' $false
Grab 'strands-hooks'       'https://strandsagents.com/latest/documentation/docs/user-guide/concepts/agents/hooks/' $false
Grab 'openai-agents-guardrails' 'https://openai.github.io/openai-agents-python/guardrails/' $false
