$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path research/vendor | Out-Null
function Grab($name, $url, $raw) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 35
    $t = $r.Content
    if (-not $raw) { $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&#39;',"'" -replace '&quot;','"' -replace '\s{2,}',' ' }
    [IO.File]::WriteAllText((Join-Path (Get-Location) "research/vendor/$name.txt"), $t)
    "ok $name ($($t.Length) bytes)"
  } catch { "fail $name : $($_.Exception.Message)" }
}
Grab 'agents-cli' 'https://raw.githubusercontent.com/google/agents-cli/main/README.md' $true
Grab 'aws-agentcore' 'https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html' $false
Grab 'azure-foundry-agents' 'https://learn.microsoft.com/en-us/azure/ai-foundry/agents/overview' $false
Grab 'vertex-agent-engine' 'https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview' $false
Grab 'langsmith-obs' 'https://docs.langchain.com/langsmith/observability-concepts' $false
