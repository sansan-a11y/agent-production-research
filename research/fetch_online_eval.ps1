$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root

# ---------- 1) vendor / standard docs ----------
function Grab($name, $url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 40 -MaximumRedirection 10 -Headers @{'User-Agent'=$UA; 'Accept-Language'='en-US,en;q=0.9,zh-CN;q=0.8'}
    $t = $r.Content
    if ($t -is [byte[]]) { $t = [Text.Encoding]::UTF8.GetString($t) }
    $t = ($t -replace '(?s)<script.*?</script>','') -replace '(?s)<style.*?</style>','' -replace '(?s)<nav.*?</nav>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&quot;','"' -replace '&#39;',"'" -replace '\s{2,}',' '
    if ($t.Length -lt 300) { "THIN  $name ($($t.Length)) $url"; return }
    [IO.File]::WriteAllText((Join-Path $root "research/vendor3/$name.txt"), $t)
    "ok    $name ($($t.Length))"
  } catch { "FAIL  $name : $($_.Exception.Message)" }
}

$docs = @(
  @('aws-agentcore-online-eval','https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/online-evaluation.html'),
  @('aws-agentcore-evals-how','https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/how-it-works.html'),
  @('aws-agentcore-builtin-eval','https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/built-in-evaluators.html'),
  @('aws-bedrock-eval','https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation.html'),
  @('aws-a2i-human-review','https://docs.aws.amazon.com/sagemaker/latest/dg/a2i-use-a-human-review-workforce.html'),
  @('azure-continuous-eval-new','https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/continuous-evaluation'),
  @('azure-agent-evaluators','https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/evaluation-evaluators/agent-evaluators'),
  @('vertex-genai-eval-overview','https://cloud.google.com/vertex-ai/generative-ai/docs/models/evaluation-overview'),
  @('ls-annotation-queues','https://docs.langchain.com/langsmith/annotation-queues.md'),
  @('ls-eval-concepts','https://docs.langchain.com/langsmith/evaluation-concepts.md'),
  @('ls-llm-as-judge','https://docs.langchain.com/langsmith/llm-as-judge.md'),
  @('ls-improve-judge-alignment','https://docs.langchain.com/langsmith/improve-judge-alignment.md'),
  @('lf-annotation-queues','https://langfuse.com/docs/evaluation/evaluation-methods/annotation-queues'),
  @('lf-llm-as-a-judge','https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge'),
  @('lf-human-annotation','https://langfuse.com/docs/evaluation/evaluation-methods/human-annotation'),
  @('lf-scores','https://langfuse.com/docs/evaluation/scores'),
  @('bt-docs-root','https://www.braintrust.dev/docs'),
  @('arize-ax-root','https://docs.arize.com/arize'),
  @('phoenix-evals','https://docs.arize.com/phoenix/evaluation/llm-evals'),
  @('argilla-docs','https://docs.argilla.io/en/latest/index.html'),
  @('labelstudio-guide','https://labelstud.io/guide/'),
  @('evidently-docs','https://docs.evidentlyai.com/'),
  @('giskard-docs','https://docs.giskard.ai/en/stable/index.html'),
  @('ragas-metrics','https://docs.ragas.io/en/stable/concepts/metrics/'),
  @('deepeval-metrics','https://docs.confident-ai.com/docs/metrics-introduction'),
  @('opik-online-eval','https://www.comet.com/docs/opik/evaluation/online_evaluation'),
  @('humanloop-docs','https://humanloop.com/docs'),
  @('patronus-docs','https://docs.patronus.ai/docs/introduction'),
  @('galileo-docs-root','https://v2docs.galileo.ai/what-is-galileo'),
  @('eu-ai-act-art14','https://artificialintelligenceact.eu/article/14/'),
  @('eu-ai-act-art15','https://artificialintelligenceact.eu/article/15/'),
  @('nist-ai-rmf','https://www.nist.gov/itl/ai-risk-management-framework'),
  @('cac-genai-measures','https://www.cac.gov.cn/2023-07/13/c_1690898327029107.htm'),
  @('cac-ai-labeling','https://www.cac.gov.cn/2025-03/14/c_1743654684782215.htm'),
  @('openai-evals-guide','https://platform.openai.com/docs/guides/evals')
)
"===== DOCS ====="
foreach ($d in $docs) { Grab $d[0] $d[1]; Start-Sleep -Milliseconds 400 }

# ---------- 2) arXiv ----------
function Arxiv($label, $query) {
  $u = "http://export.arxiv.org/api/query?search_query=" + [uri]::EscapeDataString($query) + "&start=0&max_results=6&sortBy=relevance"
  "`n=== $label :: $query ==="
  try {
    $x = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 40 -Headers @{'User-Agent'=$UA}).Content
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
      if ($su.Length -gt 900) { $su = $su.Substring(0,900) }
      $aid = ($id -split '/abs/')[-1]
      "  - [$aid] $ti"
      "    pub=$($pu.Substring(0,10)) | $($names)"
      "    $su"
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 3
}

$aq = @(
  @('trust-or-escalate','all:"selective evaluation" AND all:"human agreement" AND all:"LLM judge"'),
  @('selective-prediction','all:"selective classification" AND all:"abstention" AND all:"risk"'),
  @('learn-to-defer','all:"learning to defer" AND all:"expert" AND all:"human"'),
  @('conformal-llm','all:"conformal prediction" AND all:"large language models"'),
  @('conformal-risk-control','all:"conformal risk control"'),
  @('judge-reliability','all:"LLM-as-a-judge" AND all:"reliability" AND all:"bias"'),
  @('judge-human-agreement','all:"LLM judge" AND all:"human annotation" AND all:"agreement"'),
  @('reward-overopt','all:"reward model" AND all:"overoptimization"'),
  @('ai-control','all:"AI control" AND all:"untrusted model" AND all:"monitoring"'),
  @('verbalized-uncertainty','all:"calibration" AND all:"verbalized uncertainty" AND all:"language model"'),
  @('cascade-routing','all:"cascade" AND all:"LLM routing" AND all:"cost"'),
  @('agent-trajectory-eval','all:"agent" AND all:"trajectory" AND all:"evaluation" AND all:"tool use"'),
  @('agent-failure-taxonomy','all:"agent" AND all:"failure" AND all:"taxonomy" AND all:"debugging"'),
  @('hitl-review-queue','all:"human-in-the-loop" AND all:"annotation" AND all:"quality control"'),
  @('audit-sampling-guarantee','all:"statistical guarantee" AND all:"audit" AND all:"sampling" AND all:"error rate"'),
  @('rubric-judge','all:"rubric" AND all:"LLM judge" AND all:"evaluation"'),
  @('safety-case-assurance','all:"safety case" AND all:"machine learning" AND all:"assurance"'),
  @('automation-bias','all:"automation bias" AND all:"decision" AND all:"AI"')
)
"`n===== ARXIV ====="
foreach ($q in $aq) { Arxiv $q[0] $q[1] }

# ---------- 3) GitHub topic scan ----------
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
function Q([string]$q, [int]$n = 10) {
  $url = "https://api.github.com/search/repositories?q=" + [uri]::EscapeDataString($q) + "&sort=stars&order=desc&per_page=$n"
  "=== $q ==="
  try {
    $r = Invoke-RestMethod -Uri $url -Headers $h -TimeoutSec 45
    "  total=$($r.total_count)"
    foreach ($i in $r.items) {
      $d = ($i.description -replace '\s+',' ')
      if ($d -and $d.Length -gt 130) { $d = $d.Substring(0,130) }
      "  {0,-46} *{1,-7} push={2} :: {3}" -f $i.full_name, $i.stargazers_count, ([string]$i.pushed_at).Substring(0,10), $d
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 7
}
"`n===== GITHUB SCAN ====="
$gq = @(
  'llm annotation queue human review',
  'llm evaluation platform human feedback',
  'llm as judge alignment human labels',
  'agent trajectory evaluation benchmark',
  'uncertainty quantification llm abstention',
  'conformal prediction llm',
  'human in the loop labeling tool llm',
  'llm guardrails output verification runtime',
  'agent task success verifier reward',
  'llm hallucination detection production monitoring',
  'data annotation quality inter annotator agreement',
  'review queue moderation escalation ai',
  'llm observability online evaluation',
  'agent evaluation harness trajectory scoring'
)
$out = foreach ($q in $gq) { Q $q; "" }
$out | Set-Content -Encoding UTF8 research/gh_scan_online_eval.txt
"gh scan done: $($out.Count) lines"

# ---------- 4) repo metadata snapshot ----------
function Meta($full) {
  try {
    $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$full" -Headers $h -TimeoutSec 40
    $rel = ''
    try { $rr = Invoke-RestMethod -Uri "https://api.github.com/repos/$full/releases/latest" -Headers $h -TimeoutSec 30; $rel = $rr.tag_name } catch { $rel = '-' }
    "{0,-44} stars={1,-7} push={2} release={3,-14} lic={4}" -f $r.full_name, $r.stargazers_count, ([string]$r.pushed_at).Substring(0,10), $rel, $r.license.spdx_id
  } catch { "FAIL $full : $($_.Exception.Message)" }
}
"`n===== META ====="
$repos = @(
  'argilla-io/argilla','HumanSignal/label-studio','evidentlyai/evidently','Giskard-AI/giskard','explodinggradients/ragas',
  'confident-ai/deepeval','Arize-ai/phoenix','langfuse/langfuse','comet-ml/opik','traceloop/openllmetry',
  'openai/evals','EleutherAI/lm-evaluation-harness','UKGovernmentBEIS/inspect_ai','stanfordnlp/helm','sierra-research/tau2-bench',
  'metauto-ai/agent-as-a-judge','cvs-health/uqlm','Liyan06/MiniCheck','potsawee/selfcheckgpt','vectara/hallucination-leaderboard',
  'guardrails-ai/guardrails','NVIDIA-NeMo/Guardrails','openai/openai-agents-python','langchain-ai/langgraph','promptfoo/promptfoo',
  'bentoml/BentoML','microsoft/promptflow','Azure/azure-sdk-for-python','googleapis/python-aiplatform','aws/amazon-bedrock-agentcore-samples',
  'aikitoria/awesome-llm-evaluation','benchflow-ai/awesome-evals','OpenBMB/AgentBench','OpenBMB/ToolBench','SylphAI-Inc/AdalFlow',
  'UCL-DARK/awesome-llm-evaluation','open-compass/opencompass','huggingface/lighteval','stanford-crfm/helm','wandb/weave',
  'lastmile-ai/mcp-agent','dbt-labs/dbt-utils','netflix/metaflow','mlflow/mlflow','zenml-io/zenml','clearml/clearml',
  'activeloopai/deeplake','inspect-ai/inspect','explosion/prodigy','doccano/doccano','chinese-poetry/chinese-poetry',
  'snorkel-ai/snorkel','cleanlab/cleanlab','autogluon/autogluon','openai/whisper','kubernetes-sigs/agent-sandbox'
)
$mout = foreach ($r in $repos) { Meta $r; Start-Sleep -Seconds 3 }
$mout | Set-Content -Encoding UTF8 research/meta6.txt
"meta done: $($mout.Count) lines"
"### ALL DONE ###"
