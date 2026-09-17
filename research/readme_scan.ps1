$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github.raw' }
$repos = @(
 'langfuse/langfuse','Arize-ai/phoenix','lmnr-ai/lmnr','wandb/weave','langwatch/langwatch',
 'openlit/openlit','Jwuthri/Tracely-ai','future-agi/future-agi','promptfoo/promptfoo',
 'explodinggradients/ragas','confident-ai/deepeval','traceloop/openllmetry','Helicone/helicone',
 'OpenPipe/OpenPipe','agentops-ai/agentops','evidentlyai/evidently'
)
function TryReadme($r) {
  foreach ($name in @('README.md','readme.md','README.rst')) {
    try {
      $t = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/$r/HEAD/$name" -Headers $h -TimeoutSec 30
      return $t
    } catch {}
  }
  return $null
}
foreach ($r in $repos) {
  "########## $r"
  $t = TryReadme $r
  if (-not $t) { "  (no readme)"; continue }
  $lines = $t -split "`n"
  "  lines=$($lines.Count)"
  $hit = $lines | Where-Object { $_ -match '(?i)dataset|test ?set|regression test|production (trace|traffic|data|log)|trace[s]? (into|to) (a )?(dataset|eval)' }
  $i = 0
  foreach ($l in $hit) { $i++; if ($i -gt 12) { break }; $s = ($l -replace '\s+',' ').Trim(); if ($s.Length -gt 165) { $s = $s.Substring(0,165) }; "  - $s" }
  Start-Sleep -Seconds 1
}
