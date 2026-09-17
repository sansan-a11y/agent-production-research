$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
$repos = @('langfuse/langfuse','Arize-ai/phoenix','mlflow/mlflow','wandb/weave','lmnr-ai/lmnr','langwatch/langwatch','future-agi/future-agi','confident-ai/deepeval','explodinggradients/ragas','openlit/openlit','Jwuthri/Tracely-ai','traceloop/openllmetry','Helicone/helicone','agentops-ai/agentops','truera/trulens','promptfoo/promptfoo','mirascope/lilypad')
foreach ($r in $repos) {
  try {
    $i = Invoke-RestMethod -Uri "https://api.github.com/repos/$r" -Headers $h -TimeoutSec 30
    $lic = if ($i.license) { $i.license.spdx_id } else { 'NONE' }
    "{0,-32} lic={1,-16} stars={2,-7} lang={3,-12} push={4}" -f $i.full_name, $lic, $i.stargazers_count, $i.language, ([string]$i.pushed_at).Substring(0,10)
  } catch { "{0,-32} ERR {1}" -f $r, $_.Exception.Message }
  Start-Sleep -Seconds 1
}
