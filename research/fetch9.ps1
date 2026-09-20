$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path research/pages4 | Out-Null
function Raw($repo, $path, $name) {
  foreach ($br in @('main','master')) {
    try {
      $r = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$repo/$br/$path" -UseBasicParsing -TimeoutSec 30
      $t = $r.Content
      if ($t.Length -lt 200) { continue }
      $file = if ($name) { $name } else { ($repo -replace '/','__') + '.md' }
      [IO.File]::WriteAllText((Join-Path (Get-Location) "research/pages4/$file"), $t)
      "ok   $repo ($($t.Length) bytes) -> $file"; return
    } catch { }
  }
  "FAIL $repo/$path"
}
Raw 'microsoft/agent-governance-toolkit' 'README.md' 'microsoft__agent-governance-toolkit.md'
Raw 'FailproofAI/failproofai' 'README.md' 'FailproofAI__failproofai.md'
Raw 'Tencent/AI-Infra-Guard' 'README.md' 'Tencent__ai-infra-guard.md'
Raw 'secureagentics/Adrian' 'README.md' 'secureagentics__adrian.md'
Raw 'cvs-health/uqlm' 'README.md' 'cvs-health__uqlm.md'
Raw 'maximhq/bifrost' 'README.md' 'maximhq__bifrost.md'
Raw 'superagent-ai/superagent' 'README.md' 'superagent-ai__superagent.md'
Raw 'NVIDIA-NeMo/Guardrails' 'README.md' 'nvidia-nemo__guardrails.md'
Raw 'kenryu42/cc-safety-net' 'README.md' 'kenryu42__cc-safety-net.md'
Raw 'nolabs-ai/nono' 'README.md' 'nolabs-ai__nono.md'
Raw 'valqore/valqore' 'README.md' 'valqore__valqore.md'
Raw 'open-multi-agent/open-multi-agent' 'README.md' 'open-multi-agent__open-multi-agent.md'
Raw 'rungalileo/galileo-python' 'README.md' 'rungalileo__galileo-python.md'
Raw 'Liyan06/MiniCheck' 'README.md' 'Liyan06__minicheck.md'
Raw 'braintrustdata/braintrust-sdk' 'README.md' 'braintrustdata__braintrust-sdk2.md'
Raw 'sierra-research/tau2-bench' 'README.md' 'sierra-research__tau2-bench2.md'
Raw 'laude-institute/terminal-bench' 'README.md' 'laude-institute__terminal-bench.md'
Raw 'princeton-pli/hal-harness' 'README.md' 'princeton-pli__hal-harness2.md'
Raw 'anthropics/claude-code' 'README.md' 'anthropics__claude-code.md'
Raw 'google-gemini/gemini-cli' 'README.md' 'google-gemini__gemini-cli.md'
