$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }

function Q([string]$q, [int]$n = 10) {
  $url = "https://api.github.com/search/repositories?q=" + [uri]::EscapeDataString($q) + "&sort=stars&order=desc&per_page=$n"
  try {
    $r = Invoke-RestMethod -Uri $url -Headers $h -TimeoutSec 40
    "  total=$($r.total_count)"
    foreach ($i in $r.items) {
      "  {0,-52} *{1,-7} push={2} :: {3}" -f $i.full_name, $i.stargazers_count, $i.pushed_at.ToString('yyyy-MM-dd'), (($i.description -replace '\s+',' ') -replace '^(.{105}).*$','$1...')
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 7
}

$queries = @(
  'agent observability',
  'llm observability tracing',
  'llm gateway proxy routing',
  'llm evaluation framework',
  'prompt management versioning',
  'llm guardrails safety',
  'ai agent sandbox code execution',
  'mcp gateway registry',
  'agent memory long term',
  'durable execution workflow',
  'agent registry catalog',
  'topic:agentops',
  'topic:llmops',
  'topic:ai-agents stars:>500 pushed:>2026-05-01',
  'topic:mcp pushed:>2026-06-01 stars:>200',
  'ai agent deployment platform kubernetes'
)

$out = foreach ($q in $queries) { "=== $q ==="; Q $q; "" }
$out | Set-Content -Encoding UTF8 research/gh_scan_1.txt
$out
