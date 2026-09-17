$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'Mozilla/5.0 codex-research' }
$urls = @(
 'https://langwatch.ai/docs/datasets/introduction',
 'https://laminar.sh/docs/datasets/introduction',
 'https://arize.com/docs/phoenix/datasets-and-experiments/how-to-datasets',
 'https://docs.helicone.ai/features/datasets',
 'https://trulens.org',
 'https://docs.openlit.io/latest/open-ground'
)
foreach ($u in $urls) {
  "########## $u"
  try {
    $r = Invoke-WebRequest -Uri $u -Headers $h -TimeoutSec 35 -UseBasicParsing
    $txt = $r.Content -replace '(?s)<script.*?</script>','' -replace '(?s)<style.*?</style>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&#x27;',"'" -replace '&amp;','&' -replace '&quot;','"' -replace '\s+',' '
    $sents = $txt -split '(?<=[.!?])\s+'
    $hit = $sents | Where-Object { $_ -match '(?i)(production (traces|data|logs))|(from (your )?traces)|(add (a )?trace)|(trace.{0,30}dataset)|(dataset.{0,30}trace)' }
    $i=0; foreach ($s in $hit) { $i++; if ($i -gt 6) { break }; $s=$s.Trim(); if ($s.Length -gt 220) { $s=$s.Substring(0,220) }; "  - $s" }
    if (-not $hit) { "  (no hit; len=$($txt.Length))" }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 1
}
