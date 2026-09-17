$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'Mozilla/5.0 codex-research' }
$urls = @(
 'https://langfuse.com/docs/evaluation/experiments/datasets',
 'https://arize.com/docs/phoenix/datasets-and-experiments/overview-datasets',
 'https://laminar.sh/docs/signals/introduction',
 'https://langwatch.ai/docs/datasets/introduction',
 'https://weave-docs.wandb.ai/guides/core-types/datasets',
 'https://mlflow.org/docs/latest/genai/datasets/',
 'https://docs.ragas.io/en/stable/howtos/integrations/_langfuse/',
 'https://mirascope.com/lilypad'
)
foreach ($u in $urls) {
  "########## $u"
  try {
    $r = Invoke-WebRequest -Uri $u -Headers $h -TimeoutSec 35 -UseBasicParsing
    $txt = $r.Content -replace '(?s)<script.*?</script>','' -replace '(?s)<style.*?</style>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&#x27;',"'" -replace '&amp;','&' -replace '&quot;','"' -replace '\s+',' '
    $sents = $txt -split '(?<=[.!?])\s+'
    $hit = $sents | Where-Object { $_ -match '(?i)(from (your )?(production )?(traces|observations|logs|spans))|(add (a )?trace)|(trace.{0,25}dataset)|(dataset.{0,25}trace)|signal' }
    $i=0; foreach ($s in $hit) { $i++; if ($i -gt 8) { break }; $s=$s.Trim(); if ($s.Length -gt 230) { $s=$s.Substring(0,230) }; "  - $s" }
    if (-not $hit) { "  (no keyword hit; len=$($txt.Length))" }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 1
}
