$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
foreach ($r in @('promptfoo/promptfoo','Portkey-AI/gateway','apache/apisix','NVIDIA/garak','UKGovernmentBEIS/inspect_ai','paperclipai/paperclip','AgentOps-AI/agentops','kubernetes-sigs/agent-sandbox','kagent-dev/kagent','coze-dev/coze-loop','VoltAgent/voltagent','ifixai-ai/iFixAi','ethz-spylab/agentdojo','alibaba/higress','IBM/mcp-context-forge','modelcontextprotocol/registry','a2aproject/A2A','temporalio/temporal','restatedev/restate','dapr/dapr-agents','googleapis/genai-toolbox','strands-agents/sdk-python','microsoft/agent-framework','pydantic/pydantic-ai','openlit/openlit','truera/trulens','zenml-io/zenml','VoltAgent/voltagent','envoyproxy/ai-gateway','langgenius/dify','spring-projects/spring-ai')) {
  $s='?'; $v='?'
  try { $s = (Invoke-RestMethod -Uri "https://img.shields.io/github/stars/$r.json" -TimeoutSec 20).value } catch {}
  try { $v = (Invoke-RestMethod -Uri "https://img.shields.io/github/v/release/$r.json" -TimeoutSec 20).value } catch {}
  "{0,-40} stars={1,-8} release={2}" -f $r, $s, $v
}
