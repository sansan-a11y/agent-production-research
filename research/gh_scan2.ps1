$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
function Q([string]$q, [int]$n = 10) {
  $url = "https://api.github.com/search/repositories?q=" + [uri]::EscapeDataString($q) + "&sort=stars&order=desc&per_page=$n"
  try {
    $r = Invoke-RestMethod -Uri $url -Headers $h -TimeoutSec 40
    "  total=$($r.total_count)"
    foreach ($i in $r.items) {
      $d = ([string]$i.pushed_at)
      if ($d.Length -gt 10) { $d = $d.Substring(0,10) }
      $desc = ([string]$i.description) -replace '\s+',' '
      if ($desc.Length -gt 100) { $desc = $desc.Substring(0,100) + '...' }
      "  {0,-50} *{1,-7} push={2} :: {3}" -f $i.full_name, $i.stargazers_count, $d, $desc
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 7
}
$queries = @(
  'in:name,description,readme "agent evals"','agentic evaluation benchmark','context engineering llm',
  'llm router model selection','ai sre incident response','llm cost token tracking','agent tracing opentelemetry genai',
  'prompt versioning registry','feature flag progressive delivery','ai red teaming prompt injection',
  'multi agent orchestration framework 2026','llm inference gateway kubernetes','tool calling permission policy',
  'topic:agentops stars:>100','agent deployment canary rollout','evaluation harness agent benchmark'
)
$out = foreach ($q in $queries) { "=== $q ==="; Q $q; "" }
$out | Set-Content -Encoding UTF8 research/gh_scan_2.txt
$out
