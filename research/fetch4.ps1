$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
$tree = Invoke-RestMethod -Uri 'https://api.github.com/repos/open-telemetry/semantic-conventions-genai/git/trees/main?recursive=1' -Headers $h -TimeoutSec 40
$mds = $tree.tree | Where-Object { $_.path -like '*.md' } | Select-Object -ExpandProperty path
"FILES:"; $mds
New-Item -ItemType Directory -Force -Path research/otel | Out-Null
foreach ($p in $mds) {
  if ($p -like 'docs/*' -or $p -like '*.md') {
    $name = ($p -replace '[/\\]','__')
    try { $r = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/open-telemetry/semantic-conventions-genai/main/$p" -UseBasicParsing -TimeoutSec 25
      [IO.File]::WriteAllText((Join-Path (Get-Location) "research/otel/$name"), $r.Content)
      "ok $p ($($r.Content.Length))" } catch { "fail $p" } }
}
