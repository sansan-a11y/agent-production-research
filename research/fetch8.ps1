$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path research/vendor2 | Out-Null
function Grab($name, $url, $raw) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 40 -MaximumRedirection 10 -Headers @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36'}
    $t = $r.Content
    if (-not $raw) {
      $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '(?s)<nav.*?</nav>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&#39;',"'" -replace '&quot;','"' -replace '&gt;','>' -replace '&lt;','<' -replace '\s{2,}',' '
    }
    if ($t.Length -lt 300) { "THIN $name ($($t.Length) bytes)"; return }
    [IO.File]::WriteAllText((Join-Path (Get-Location) "research/vendor2/$name.txt"), $t)
    "ok   $name ($($t.Length) bytes)"
  } catch { "FAIL $name : $($_.Exception.Message)" }
}
# 可观测平台的在线评测
Grab 'langsmith-onlineevals' 'https://docs.langchain.com/langsmith/online-evaluations' $false
Grab 'langsmith-automations' 'https://docs.langchain.com/langsmith/automations' $false
Grab 'langchain-middleware'  'https://docs.langchain.com/oss/python/langchain/middleware' $false
Grab 'langgraph-interrupts' 'https://docs.langchain.com/oss/python/langgraph/interrupts' $false
Grab 'langfuse-monitors-a'  'https://langfuse.com/docs/metrics/features/monitors' $false
Grab 'langfuse-monitors-b'  'https://langfuse.com/docs/observability/features/monitors' $false
Grab 'braintrust-automations' 'https://www.braintrust.dev/docs/monitor/automations' $false
Grab 'weave-monitors'      'https://weave-docs.wandb.ai/guides/evaluation/monitors' $false
Grab 'weave-monitors-b'    'https://weave-docs.wandb.ai/guides/tools/monitors' $false
Grab 'phoenix-onlineeval'  'https://arize.com/docs/phoenix/evaluation/how-to-evals/online-evals' $false
Grab 'phoenix-onlineeval-b' 'https://arize.com/docs/phoenix/evaluation/online-evaluation' $false
Grab 'opik-onlineeval'     'https://www.comet.com/docs/opik/evaluation/online_evaluation' $false
# 框架 hook 机制（修正/补充）
Grab 'strands-hooks-a'     'https://strandsagents.com/docs/user-guide/concepts/agents/hooks/' $false
Grab 'strands-hooks-b'     'https://strandsagents.com/latest/documentation/docs/user-guide/concepts/agents/hooks/' $false
Grab 'adk-evaluate'        'https://google.github.io/adk-docs/evaluate/' $false
Grab 'vertex-checkgrounding' 'https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/grounding-check-overview' $false
Grab 'vertex-checkgrounding-b' 'https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/check-grounding' $false
Grab 'vertex-agentengine-eval' 'https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/evaluate' $false
Grab 'aws-agentcore-evals' 'https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/evaluations.html' $false
Grab 'azure-continuous-eval' 'https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/continuous-eval' $false
Grab 'azure-redteam-agent'  'https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/ai-red-teaming-agent' $false
Grab 'azure-monitor-agents'  'https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/monitor-agents' $false
# 审计/红队/合规
Grab 'anthropic-cc'        'https://www.anthropic.com/research/constitutional-classifiers' $false
Grab 'anthropic-petri'     'https://www.anthropic.com/research/petri-open-source-auditing' $false
Grab 'owasp-agentic'       'https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2025/' $false
Grab 'owasp-llm-top10'     'https://genai.owasp.org/llm-top-10/' $false
# 商业评测/监督厂商
Grab 'patronus-docs'       'https://docs.patronus.ai/docs/introduction' $false
Grab 'galileo-docs'        'https://docs.galileo.ai/what-is-galileo' $false
Grab 'vijil-docs'          'https://docs.vijil.ai/' $false
