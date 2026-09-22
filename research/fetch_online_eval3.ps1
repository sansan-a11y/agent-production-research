$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root

function Grab($name, $url, $raw = $false, $to = 60) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $to -MaximumRedirection 10 -Headers @{'User-Agent'=$UA; 'Accept-Language'='en-US,en;q=0.9,zh-CN;q=0.8'}
    $t = $r.Content
    if ($t -is [byte[]]) { $t = [Text.Encoding]::UTF8.GetString($t) }
    if (-not $raw) { $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '(?s)<nav.*?</nav>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&quot;','"' -replace '&#39;',"'" -replace '\s{2,}',' ' }
    if ($t.Length -lt 200) { "THIN  $name ($($t.Length)) $url"; return }
    [IO.File]::WriteAllText((Join-Path $root "research/vendor3/$name.txt"), $t)
    "ok    $name ($($t.Length))"
  } catch { "FAIL  $name : $($_.Exception.Message)" }
}
"===== ROUND3 DOCS ====="
Grab 'argilla-docs-a'  'https://docs.vllm.ai/' $false 30
Grab 'argilla-hf'      'https://huggingface.co/docs/argilla/index' $false 60
Grab 'argilla-gh-readme' 'https://raw.githubusercontent.com/argilla-io/argilla/main/README.md' $true 60
Grab 'labelstudio-guide3' 'https://labelstud.io/guide/' $false 60
Grab 'labelstudio-gh'  'https://raw.githubusercontent.com/HumanSignal/label-studio/develop/README.md' $true 60
Grab 'evidently-gh'    'https://raw.githubusercontent.com/evidentlyai/evidently/main/README.md' $true 60
Grab 'evidently-monitor' 'https://docs.evidentlyai.com/monitoring/monitoring_overview' $false 60
Grab 'vertex-eval3'    'https://cloud.google.com/vertex-ai/generative-ai/docs/models/evaluation-overview' $false 90
Grab 'vertex-agent-eval' 'https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/evaluate' $false 90
Grab 'azure-search-out' 'https://learn.microsoft.com/api/search?search=continuous%20evaluation%20agent%20foundry&locale=en-us' $true 60
Grab 'azure-human-eval' 'https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/evaluation-approach-gen-ai' $false 60
Grab 'aws-agentcore-online-b' 'https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/online-evaluation.html' $false 60
Grab 'eu-ai-act-art14b' 'https://artificialintelligenceact.eu/article/14/' $false 60
Grab 'nist-rmf-ai'     'https://www.nist.gov/itl/ai-risk-management-framework' $false 60
Grab 'iso-42001-b'     'https://www.iso.org/standard/42001' $false 60
Grab 'cache-genai'     'https://www.cac.gov.cn/2023-07/13/c_1690898327029107.htm' $false 60
Grab 'cache-label'     'https://www.cac.gov.cn/2025-03/14/c_1743654684782215.htm' $false 60
Grab 'otl-cov'         'https://opentelemetry.io/docs/specs/semconv/gen-ai/' $false 60

# arXiv round 3
function Arxiv($label, $query) {
  $u = "http://export.arxiv.org/api/query?search_query=" + [uri]::EscapeDataString($query) + "&start=0&max_results=5&sortBy=relevance"
  "`n=== $label :: $query ==="
  try {
    $x = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 45 -Headers @{'User-Agent'=$UA}).Content
    $ms = [regex]::Matches($x, '(?s)<entry>(.*?)</entry>')
    if ($ms.Count -eq 0) { "  no entries"; return }
    foreach ($m in $ms) {
      $e = $m.Groups[1].Value
      $ti = [regex]::Match($e,'(?s)<title>(.*?)</title>').Groups[1].Value
      $id = [regex]::Match($e,'(?s)<id>(.*?)</id>').Groups[1].Value
      $pu = [regex]::Match($e,'(?s)<published>(.*?)</published>').Groups[1].Value
      $su = [regex]::Match($e,'(?s)<summary>(.*?)</summary>').Groups[1].Value
      $names = ([regex]::Matches($e,'(?s)<name>(.*?)</name>') | ForEach-Object { $_.Groups[1].Value }) -join ', '
      $ti = ($ti -replace '\s+',' ').Trim(); $su = ($su -replace '\s+',' ').Trim()
      if ($su.Length -gt 800) { $su = $su.Substring(0,800) }
      "  - [$(($id -split '/abs/')[-1])] $ti"
      "    pub=$($pu.Substring(0,10)) | $($names)"
      "    $su"
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 3
}
"`n===== ROUND3 ARXIV ====="
Arxiv 'overreliance-llm-advice' 'all:"overreliance" AND all:"large language models" AND all:"advice"'
Arxiv 'human-ai-complementarity' 'all:"complementarity" AND all:"human-AI" AND all:"deferral"'
Arxiv 'capacity-constrained-deferral' 'all:"defer" AND all:"human" AND all:"capacity" AND all:"queue"'
Arxiv 'self-correction-limits' 'all:"self-correction" AND all:"large language models" AND all:"reasoning"'
Arxiv 'spec-gaming-agent' 'all:"reward hacking" AND all:"agents"'
Arxiv 'position-bias-judge2' 'all:"position bias" AND all:"LLM judges"'
Arxiv 'llm-uncertainty-benchmark' 'all:"uncertainty quantification" AND all:"large language models" AND all:"benchmark"'
Arxiv 'escalation-policy-agent' 'all:"escalation" AND all:"agent" AND all:"human oversight"'
Arxiv 'eval-contamination-leaderboard' 'all:"leaderboard" AND all:"evaluation" AND all:"gaming" AND all:"language model"'
Arxiv 'production-monitoring-drift-llm' 'all:"monitoring" AND all:"distribution shift" AND all:"deployed" AND all:"language model"'
"### ROUND3 DONE ###"
