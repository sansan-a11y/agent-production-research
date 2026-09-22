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

"===== ROUND2: doc indexes ====="
Grab 'idx-langfuse'     'https://langfuse.com/llms.txt' $true
Grab 'idx-arize'        'https://docs.arize.com/llms.txt' $true
Grab 'idx-braintrust'   'https://www.braintrust.dev/llms.txt' $true
Grab 'idx-langsmith'    'https://docs.langchain.com/llms.txt' $true
Grab 'idx-galileo'      'https://v2docs.galileo.ai/llms.txt' $true
Grab 'idx-opik'         'https://www.comet.com/docs/opik/llms.txt' $true
Grab 'idx-giskard'      'https://docs.giskard.ai/llms.txt' $true
Grab 'idx-argilla'      'https://argilla.io/llms.txt' $true
Grab 'idx-weave'        'https://docs.wandb.ai/llms.txt' $true

"===== ROUND2: fixed docs ====="
Grab 'lf-scores-overview' 'https://langfuse.com/docs/evaluation/scores/overview'
Grab 'lf-online-getstarted' 'https://langfuse.com/docs/evaluation/get-started/online'
Grab 'lf-annotation-queues2' 'https://langfuse.com/docs/evaluation/evaluation-methods/annotation-queues.md' $true
Grab 'opik-overview'    'https://www.comet.com/docs/opik/evaluation/overview.md' $true
Grab 'opik-concepts'    'https://www.comet.com/docs/opik/evaluation/concepts.md' $true
Grab 'argilla-latest'   'https://docs.argilla.io/en/latest/index.html'
Grab 'argilla-root'     'https://argilla.io/'
Grab 'labelstudio-guide2' 'https://labelstud.io/guide/index.html'
Grab 'evidently-docs2'  'https://docs.evidentlyai.com/'
Grab 'cleanlab-docs'    'https://docs.cleanlab.ai/stable/index.html'
Grab 'vertex-eval'      'https://cloud.google.com/vertex-ai/generative-ai/docs/models/evaluation-overview' $false 90
Grab 'vertex-eval-b'    'https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/evaluation-overview' $false 90
Grab 'azure-eval-search' 'https://learn.microsoft.com/api/search?search=continuous%20evaluation%20agent%20foundry&locale=en-us' $true 60

"===== ROUND2: aws md attempts ====="
Grab 'aws-agentcore-online-eval-md' 'https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/online-evaluation.html.md' $true 45
Grab 'aws-agentcore-samples-online' 'https://raw.githubusercontent.com/aws-samples/amazon-bedrock-agentcore-samples/main/01-tutorials/05-AgentCore-evaluations/README.md' $true 45
Grab 'aws-agentcore-eval-hiw'  'https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/how-it-works.md' $true 45
Grab 'aws-a2i-overview'  'https://docs.aws.amazon.com/sagemaker/latest/dg/a2i-human-review-workflows.html' $false 45
Grab 'aws-a2i-html'      'https://docs.aws.amazon.com/sagemaker/latest/dg/a2i-use-a-human-review-workforce.html' $false 45

"===== ROUND2: china / standards ====="
Grab 'cac-genai-measures2' 'https://www.cac.gov.cn/2023-07/13/c_1690898327029107.htm' $false 60
Grab 'cac-labeling2'    'https://www.cac.gov.cn/2025-03/14/c_1743654684782215.htm' $false 60
Grab 'tc260-genai-label' 'https://www.tc260.org.cn/' $false 45
Grab 'nist-genai-profile' 'https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf' $true 90
Grab 'iso-42001'        'https://www.iso.org/standard/81230.html' $false 60
"### ROUND2 DONE ###"
