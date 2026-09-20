$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Grab($name, $url, $raw) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 35 -MaximumRedirection 10 -Headers @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36'}
    $t = $r.Content
    if (-not $raw) { $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '\s{2,}',' ' }
    if ($t.Length -lt 250) { "THIN $name ($($t.Length))"; return }
    [IO.File]::WriteAllText((Join-Path (Get-Location) "research/vendor2/$name.txt"), $t); "ok   $name ($($t.Length))"
  } catch { "FAIL $name : $($_.Exception.Message)" }
}
Grab 'langsmith-onlineevals' 'https://docs.langchain.com/langsmith/online-evaluations.md' $true
Grab 'langsmith-automations' 'https://docs.langchain.com/langsmith/automations.md' $true
Grab 'langchain-middleware'  'https://docs.langchain.com/oss/python/langchain/middleware.md' $true
Grab 'langgraph-durable'     'https://docs.langchain.com/oss/python/langgraph/durable-execution.md' $true
Grab 'ags-acs-spec'          'https://microsoft.github.io/agent-governance-toolkit/specifications/agent-control-specification/' $false
Grab 'ags-sre-spec'          'https://microsoft.github.io/agent-governance-toolkit/specifications/agent-sre-governance/' $false
Grab 'strands-hooks-md'      'https://strandsagents.com/docs/user-guide/concepts/agents/hooks.md' $true
Grab 'phoenix-onlineeval-md' 'https://arize.com/docs/phoenix/evaluation/online-evaluation.md' $true
Grab 'opik-onlineeval-md'    'https://www.comet.com/docs/opik/evaluation/online_evaluation.md' $true
Grab 'patronus-llms'         'https://docs.patronus.ai/llms.txt' $true
Grab 'owasp-asi'             'https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/' $false
Grab 'langfuse-judge-b'      'https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge.md' $true
Grab 'datadog-evals-md'      'https://docs.datadoghq.com/llm_observability/evaluations/index.md' $true
