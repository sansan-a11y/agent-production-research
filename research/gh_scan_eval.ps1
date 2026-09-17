$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
function Q([string]$q, [int]$n = 8) {
  $url = "https://api.github.com/search/repositories?q=" + [uri]::EscapeDataString($q) + "&sort=stars&order=desc&per_page=$n"
  "=== $q ==="
  try {
    $r = Invoke-RestMethod -Uri $url -Headers $h -TimeoutSec 40
    "  total=$($r.total_count)"
    foreach ($i in $r.items) {
      $d = ($i.description -replace '\s+',' ')
      if ($d.Length -gt 110) { $d = $d.Substring(0,110) }
      "  {0,-50} *{1,-7} push={2} :: {3}" -f $i.full_name, $i.stargazers_count, ([string]$i.pushed_at).Substring(0,10), $d
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 7
}
$queries = @(
  'llm traces to eval dataset',
  'production trace dataset evaluation llm',
  'topic:llmops evaluation dataset',
  'agent eval dataset from logs',
  'online evaluation llm',
  'trace to test case',
  'failure mining llm traces',
  'llm observability open source',
  'agent regression testing traces',
  'synthetic data from production traffic llm'
)
$out = foreach ($q in $queries) { Q $q; "" }
$out | Set-Content -Encoding UTF8 research\gh_scan_eval.txt
$out
