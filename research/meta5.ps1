$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$h = @{ 'User-Agent' = 'codex-research'; 'Accept' = 'application/vnd.github+json' }
$repos = @(
  'microsoft/agent-governance-toolkit','FailproofAI/failproofai','Tencent/AI-Infra-Guard','secureagentics/Adrian',
  'cvs-health/uqlm','maximhq/bifrost','superagent-ai/superagent','NVIDIA-NeMo/Guardrails','kenryu42/cc-safety-net',
  'nolabs-ai/nono','valqore/valqore','open-multi-agent/open-multi-agent','rungalileo/galileo-python','Liyan06/MiniCheck',
  'braintrustdata/braintrust-sdk','sierra-research/tau2-bench','laude-institute/terminal-bench','princeton-pli/hal-harness',
  'vectara/hallucination-leaderboard','potsawee/selfcheckgpt','amazon-science/refchecker','metauto-ai/agent-as-a-judge',
  'permitio/permit','vijil/vijil','NVIDIA-NeMo/Guardrails','Temporalio/sdk-python','polos-dev/polos',
  'jnamaya/SAFi','future-agi/future-agi','vllm-project/semantic-router','BoundaryML/baml',
  'anthropics/claude-code','google-gemini/gemini-cli','stripe/agent-toolkit'
)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# round-2 metadata  $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
for ($i=0; $i -lt $repos.Count; $i+=8) {
  $chunk = $repos[$i..([math]::Min($i+7,$repos.Count-1))]
  $q = (($chunk | ForEach-Object { "repo:$_" }) -join '+')
  try {
    $r = Invoke-RestMethod -Uri "https://api.github.com/search/repositories?q=$q&per_page=100" -Headers $h -TimeoutSec 45
    $lines.Add(""); $lines.Add("== batch $($i/8 + 1) : requested $($chunk.Count), returned $($r.items.Count) ==")
    foreach ($it in $r.items) {
      $lic = if ($it.license) { $it.license.spdx_id } else { 'none' }
      $d = ($it.description -replace '\s+',' '); if ($d -and $d.Length -gt 140) { $d = $d.Substring(0,140) }
      $lines.Add(("{0,-46} stars={1,-7} pushed={2} lic={3,-13} :: {4}" -f $it.full_name, $it.stargazers_count, ([string]$it.pushed_at).Substring(0,10), $lic, $d))
    }
  } catch { $lines.Add("ERR batch $($i/8+1): $($_.Exception.Message)") }
  Start-Sleep -Seconds 8
}
$lines | Set-Content -Encoding UTF8 research/meta5.txt
"meta5 done: $($lines.Count) lines"
