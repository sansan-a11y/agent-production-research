$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research' }
$targets = @(
 @{r='Arize-ai/phoenix'; f='LICENSE'},
 @{r='langfuse/langfuse'; f='LICENSE'},
 @{r='Arize-ai/phoenix'; f='README.md'},
 @{r='lmnr-ai/lmnr'; f='LICENSE'},
 @{r='Jwuthri/Tracely-ai'; f='LICENSE'}
)
foreach ($t in $targets) {
  "########## $($t.r)/$($t.f)"
  try {
    $x = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/$($t.r)/HEAD/$($t.f)" -Headers $h -TimeoutSec 30
    $lines = ($x -split "`n") | Select-Object -First 6
    foreach ($l in $lines) { "  $($l.Trim())" }
    if ($t.f -eq 'README.md') {
      $hit = ($x -split "`n") | Where-Object { $_ -match '(?i)licen[cs]e' }
      foreach ($l in $hit) { $s=$l.Trim(); if ($s.Length -gt 200) { $s=$s.Substring(0,200) }; "  >> $s" }
    }
  } catch { "  ERR: $($_.Exception.Message)" }
}
