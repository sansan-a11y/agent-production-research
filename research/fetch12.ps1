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
Grab 'acs-owasp'        'https://genai.owasp.org/resource/agent-control-standard-acs/' $false
Grab 'acs-site'         'https://agentcontrolstandard.org/' $false
Grab 'acs-github-io'    'https://agent-control-standard.github.io/' $false
Grab 'langchain-mw-custom' 'https://docs.langchain.com/oss/python/langchain/middleware/custom.md' $true
Grab 'langchain-mw-builtin' 'https://docs.langchain.com/oss/python/langchain/middleware/built-in.md' $true
Grab 'langsmith-rules'  'https://docs.langchain.com/langsmith/rules.md' $true
Grab 'strands-hooks-b'  'https://strandsagents.com/latest/documentation/docs/user-guide/concepts/agents/hooks.md' $true
Grab 'owasp-asi-list'   'https://genai.owasp.org/llm-top-10/' $true
