$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dir = 'research/pages3'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$repos = @(
 'coze-dev/coze-loop','paperclipai/paperclip','VoltAgent/voltagent','AgentOps-AI/agentops','truera/trulens',
 'zenml-io/zenml','benchflow-ai/awesome-evals','Meirtz/Awesome-Context-Engineering','ethz-spylab/agentdojo',
 'ifixai-ai/iFixAi','harveyai/harvey-labs','alibaba/higress','apache/apisix','langgenius/dify','infiniflow/ragflow',
 'agentscope-ai/agentscope','spring-projects/spring-ai','strands-agents/sdk-python','GoogleCloudPlatform/agent-starter-pack',
 'pydantic/pydantic-ai','deepset-ai/haystack','hatchet-dev/hatchet','dbos-inc/dbos-transact-py','GrowthBook/growthbook',
 'Unleash/unleash','Flagsmith/flagsmith','argoproj/argo-rollouts','argoproj/argo-cd','NVIDIA/garak','Azure/PyRIT',
 'invariantlabs-ai/mcp-scan','openlit/openlit','evidentlyai/evidently','Giskard-AI/giskard-oss',
 'microsoft/promptflow','openai/openai-agents-js','livekit/agents','pipecat-ai/pipecat','sgl-project/sglang',
 'awslabs/bedrock-agentcore-samples','aws/bedrock-agentcore-sdk-python','snyk/mcp-scan','opendatalab/MinerU',
 'modelcontextprotocol/servers','googleapis/genai-toolbox','lastmile-ai/mcp-agent','upsonic/upsonic'
)
$names = @('README.md','readme.md','README.rst')
$ok = 0; $fail = @()
foreach ($r in $repos) {
  $slug = ($r -replace '/','__'); $dest = Join-Path $dir "$slug.md"
  if (Test-Path $dest) { continue }
  $got = $false
  foreach ($b in @('HEAD','main','master')) { foreach ($n in $names) {
      try { $resp = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$r/$b/$n" -UseBasicParsing -TimeoutSec 25
        if ($resp.StatusCode -eq 200 -and $resp.Content.Length -gt 200) {
          [IO.File]::WriteAllText((Join-Path (Get-Location) $dest), $resp.Content); $got=$true; $ok++; break } } catch {} }
    if ($got) { break } }
  if (-not $got) { $fail += $r }
}
"READMEs ok=$ok"
"FAIL: " + ($fail -join ', ')

$docs = @{
 'otel-genai-spans'   = 'https://raw.githubusercontent.com/open-telemetry/semantic-conventions/main/docs/gen-ai/gen-ai-spans.md'
 'otel-genai-agent'   = 'https://raw.githubusercontent.com/open-telemetry/semantic-conventions/main/docs/gen-ai/gen-ai-agent-spans.md'
 'otel-genai-metrics' = 'https://raw.githubusercontent.com/open-telemetry/semantic-conventions/main/docs/gen-ai/gen-ai-metrics.md'
 'otel-genai-events'  = 'https://raw.githubusercontent.com/open-telemetry/semantic-conventions/main/docs/gen-ai/gen-ai-events.md'
 'otel-genai-mcp'     = 'https://raw.githubusercontent.com/open-telemetry/semantic-conventions/main/docs/gen-ai/mcp.md'
 'otel-genai-overview'= 'https://raw.githubusercontent.com/open-telemetry/semantic-conventions/main/docs/gen-ai/gen-ai.md'
}
foreach ($k in $docs.Keys) {
  try { $resp = Invoke-WebRequest -Uri $docs[$k] -UseBasicParsing -TimeoutSec 25
    [IO.File]::WriteAllText((Join-Path (Get-Location) "research/$k.md"), $resp.Content)
    "doc ok $k ($($resp.Content.Length) bytes)" } catch { "doc FAIL $k : $($_.Exception.Message)" }
}
