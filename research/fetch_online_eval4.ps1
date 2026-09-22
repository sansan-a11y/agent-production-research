$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root
function Grab($name, $url, $raw = $true, $to = 60) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $to -MaximumRedirection 10 -Headers @{'User-Agent'=$UA; 'Accept-Language'='en-US,en;q=0.9,zh-CN;q=0.8'}
    $t = $r.Content
    if ($t -is [byte[]]) { $t = [Text.Encoding]::UTF8.GetString($t) }
    if (-not $raw) { $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '(?s)<nav.*?</nav>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&quot;','"' -replace '&#39;',"'" -replace '\s{2,}',' ' }
    if ($t.Length -lt 150) { "THIN  $name ($($t.Length)) $url"; return }
    [IO.File]::WriteAllText((Join-Path $root "research/vendor3/$name.txt"), $t); "ok    $name ($($t.Length))"
  } catch { "FAIL  $name : $($_.Exception.Message)" }
}
"===== ROUND4 ====="
Grab 'opik-annotation-queues' 'https://www.comet.com/docs/opik/evaluation/advanced/annotation_queues.md'
Grab 'bt-human-review'   'https://www.braintrust.dev/docs/annotate/human-review/index.md'
Grab 'bt-score-online'   'https://www.braintrust.dev/docs/evaluate/score-online.md'
Grab 'oai-evals'         'https://platform.openai.com/docs/guides/evals.md'
Grab 'oai-graders'       'https://platform.openai.com/docs/guides/graders.md'
Grab 'giskard-eval-review' 'https://docs.giskard.ai/hub/ui/evaluations/create.md'
Grab 'galileo-idx2'      'https://docs.galileo.ai/llms.txt'
Grab 'argilla-a'         'https://docs.argilla.io/'
Grab 'argilla-hf'        'https://huggingface.co/docs/argilla/index'
Grab 'evidently-monitor' 'https://docs.evidentlyai.com/monitoring/monitoring_overview'
Grab 'azure-eval-search2' 'https://learn.microsoft.com/api/search?search=%22continuous%20evaluation%22%20foundry%20agent&locale=en-us'
Grab 'azure-foundry-obs' 'https://learn.microsoft.com/en-us/azure/foundry/concepts/observability'
Grab 'lf-corrections'    'https://langfuse.com/docs/observability/features/corrections.md'
Grab 'lf-user-feedback'  'https://langfuse.com/docs/observability/features/user-feedback.md'
Grab 'lf-sampling'       'https://langfuse.com/docs/observability/features/sampling.md'
Grab 'ls-multiturn-online' 'https://docs.langchain.com/langsmith/online-evaluations-multi-turn.md'
"### ROUND4 DONE ###"
