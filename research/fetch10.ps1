$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path research/vendor2 | Out-Null
function Grab($name, $url, $raw) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 40 -MaximumRedirection 10 -Headers @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36'}
    $t = $r.Content
    if (-not $raw) { $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&#39;',"'" -replace '&quot;','"' -replace '\s{2,}',' ' }
    if ($t.Length -lt 250) { "THIN $name ($($t.Length))"; return }
    [IO.File]::WriteAllText((Join-Path (Get-Location) "research/vendor2/$name.txt"), $t); "ok   $name ($($t.Length))"
  } catch { "FAIL $name : $($_.Exception.Message)" }
}
# 新标准 / 治理框架
Grab 'aarm-home'    'https://aarm.dev/' $false
Grab 'atf-home'     'https://agentictrustframework.ai/' $false
Grab 'agt-docs'     'https://microsoft.github.io/agent-governance-toolkit/' $false
Grab 'owasp-agentic' 'https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2025/' $false
Grab 'owasp-llm-top10' 'https://genai.owasp.org/llm-top-10/' $false
# 框架 hook / middleware 文档（走 GitHub raw 绕开站点拦截）
Grab 'strands-hooks'   'https://raw.githubusercontent.com/strands-agents/sdk-python/main/docs/user-guide/concepts/agents/hooks.md' $true
Grab 'langchain-middleware' 'https://raw.githubusercontent.com/langchain-ai/docs/main/src/oss/langchain/middleware.mdx' $true
Grab 'langsmith-onlineevals' 'https://raw.githubusercontent.com/langchain-ai/docs/main/src/langsmith/online-evaluations.mdx' $true
Grab 'langsmith-automations' 'https://raw.githubusercontent.com/langchain-ai/docs/main/src/langsmith/automations.mdx' $true
Grab 'openai-agents-tracing' 'https://raw.githubusercontent.com/openai/openai-agents-python/main/docs/tracing.md' $true
Grab 'openai-agents-hitl' 'https://raw.githubusercontent.com/openai/openai-agents-python/main/docs/human_in_the_loop.md' $true
Grab 'openai-agents-mcp'  'https://raw.githubusercontent.com/openai/openai-agents-python/main/docs/mcp.md' $true
Grab 'claude-agent-sdk-py' 'https://raw.githubusercontent.com/anthropics/claude-agent-sdk-python/main/README.md' $true
Grab 'adk-callbacks-gh'   'https://raw.githubusercontent.com/google/adk-docs/main/docs/callbacks/index.md' $true
Grab 'adk-eval-gh'        'https://raw.githubusercontent.com/google/adk-docs/main/docs/evaluate/index.md' $true
# 其他厂商在线评测（GitHub raw 兜底）
Grab 'opik-onlineeval'    'https://raw.githubusercontent.com/comet-ml/opik/main/docs/evaluation/online_evaluation.mdx' $true
Grab 'phoenix-evals'      'https://raw.githubusercontent.com/Arize-ai/phoenix/main/docs/phoenix/evaluation/online-evaluation.mdx' $true
Grab 'braintrust-automations' 'https://raw.githubusercontent.com/braintrustdata/braintrust-sdk/main/README.md' $true
# 商业监督厂商
Grab 'galileo-docs'       'https://v2docs.galileo.ai/what-is-galileo' $false
Grab 'patronus-docs'      'https://docs.patronus.ai/' $false
Grab 'vijil-docs'         'https://docs.vijil.ai/' $false
Grab 'azure-continuous-eval' 'https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/continuous-evaluation-agents' $false
Grab 'azure-monitor-agents'  'https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/monitor-agents-overview' $false
