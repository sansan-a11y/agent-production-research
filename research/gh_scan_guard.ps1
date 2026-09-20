$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
function Q([string]$q, [int]$n = 10) {
  $url = "https://api.github.com/search/repositories?q=" + [uri]::EscapeDataString($q) + "&sort=stars&order=desc&per_page=$n"
  "=== $q ==="
  try {
    $r = Invoke-RestMethod -Uri $url -Headers $h -TimeoutSec 45
    "  total=$($r.total_count)"
    foreach ($i in $r.items) {
      $d = ($i.description -replace '\s+',' ')
      if ($d -and $d.Length -gt 120) { $d = $d.Substring(0,120) }
      "  {0,-46} *{1,-7} push={2} :: {3}" -f $i.full_name, $i.stargazers_count, ([string]$i.pushed_at).Substring(0,10), $d
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 8
}
$queries = @(
  'supervisor agent llm tool call verification',
  'llm agent middleware hooks guardrail',
  'hallucination detection llm production',
  'tool call hallucination detection function calling',
  'online evaluation llm traces production',
  'agent reliability evaluation harness',
  'prompt injection detection agent firewall',
  'mcp gateway policy guardrails',
  'human in the loop agent approval workflow',
  'agent safety benchmark tool misuse',
  'llm as judge runtime scoring traces',
  'agent trajectory verification reward model',
  'ai agent governance policy engine runtime',
  'agent canary shadow deployment rollout',
  'llm output groundedness verifier',
  'topic:llm-security',
  'topic:ai-safety',
  'topic:guardrails',
  'topic:agentic-ai observability',
  'agent runtime sandbox execution isolation'
)
$out = foreach ($q in $queries) { Q $q; "" }
$out | Set-Content -Encoding UTF8 research/gh_scan_guard.txt
"scan done: $($out.Count) lines"
