$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repos = Get-ChildItem research/pages | ForEach-Object { $_.BaseName -replace '__','/' }
$rows = @()
foreach ($r in $repos) {
  $line = "{0,-45}" -f $r
  foreach ($m in @('stars','v/release','last-commit','license')) {
    $k = $m -replace '/','_'
    $url = "https://img.shields.io/github/$m/$r.json"
    $v = '?'
    try {
      $j = Invoke-RestMethod -Uri $url -TimeoutSec 20
      $v = [string]$j.value
      if (-not $v) { $v = [string]$j.message }
    } catch { $v = 'ERR' }
    $line += " {0}={1}" -f $k, $v
  }
  $rows += $line
  ""
}
$rows | Set-Content -Encoding UTF8 research/meta.txt
$rows
