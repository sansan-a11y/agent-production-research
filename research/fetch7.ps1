$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path research/pages4 | Out-Null
function Raw($repo, $path, $name) {
  foreach ($br in @('main','master')) {
    foreach ($p in @($path)) {
      $url = "https://raw.githubusercontent.com/$repo/$br/$p"
      try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        $t = $r.Content
        if ($t.Length -lt 200) { continue }
        $file = if ($name) { $name } else { ($repo -replace '/','__') + '.md' }
        [IO.File]::WriteAllText((Join-Path (Get-Location) "research/pages4/$file"), $t)
        "ok   $repo/$p ($($t.Length) bytes) -> $file"
        return
      } catch { }
    }
  }
  "FAIL $repo/$path"
}
Raw 'meta-llama/PurpleLlama' 'LlamaFirewall/README.md' 'purplellama__llamafirewall.md'
Raw 'meta-llama/PurpleLlama' 'Llama-Guard4/README.md'  'purplellama__llamaguard4.md'
Raw 'NVIDIA/NeMo-Guardrails' 'README.md' 'nvidia__nemo-guardrails.md'
Raw 'guardrails-ai/guardrails' 'README.md' 'guardrails-ai__guardrails.md'
Raw 'openai/openai-agents-python' 'README.md' 'openai__openai-agents-python.md'
Raw 'google/adk-python' 'README.md' 'google__adk-python.md'
Raw 'microsoft/agent-framework' 'README.md' 'microsoft__agent-framework.md'
Raw 'strands-agents/sdk-python' 'README.md' 'strands-agents__sdk-python.md'
Raw 'langchain-ai/langchain' 'libs/langchain/README.md' 'langchain-ai__langchain.md'
Raw 'langchain-ai/deepagents' 'README.md' 'langchain-ai__deepagents.md'
Raw 'agentgateway/agentgateway' 'README.md' 'agentgateway__agentgateway.md'
Raw 'protectai/llm-guard' 'README.md' 'protectai__llm-guard.md'
Raw 'vijil/vijil' 'README.md' 'vijil__vijil.md'
Raw 'stacklok/toolhive' 'README.md' 'stacklok__toolhive.md'
Raw 'obot-platform/obot' 'README.md' 'obot-platform__obot.md'
Raw 'abshkbh/arrakis' 'README.md' 'abshkbh__arrakis.md'
Raw 'sierra-research/tau2-bench' 'README.md' 'sierra-research__tau2-bench.md'
Raw 'sierra-research/tau-bench' 'README.md' 'sierra-research__tau-bench.md'
Raw 'princeton-pli/hal-harness' 'README.md' 'princeton-pli__hal-harness.md'
Raw 'metauto-ai/agent-as-a-judge' 'README.md' 'metauto-ai__agent-as-a-judge.md'
Raw 'thu-coai/Agent-SafetyBench' 'README.md' 'thu-coai__agent-safetybench.md'
Raw 'ryoungj/ToolEmu' 'README.md' 'ryoungj__toolemu.md'
Raw 'vectara/hallucination-leaderboard' 'README.md' 'vectara__hallucination-leaderboard.md'
Raw 'potsawee/selfcheckgpt' 'README.md' 'potsawee__selfcheckgpt.md'
Raw 'lianhua-zhao/MiniCheck' 'README.md' 'lianhua-zhao__minicheck.md'
Raw 'amazon-science/refchecker' 'README.md' 'amazon-science__refchecker.md'
Raw 'galileo-ai/galileo-python' 'README.md' 'galileo-ai__galileo-python.md'
Raw 'galileo-ai/agent-inspect' 'README.md' 'galileo-ai__agent-inspect.md'
Raw 'wandb/weave' 'README.md' 'wandb__weave.md'
Raw 'braintrustdata/braintrust-sdk' 'README.md' 'braintrustdata__braintrust-sdk.md'
Raw 'lmnr-ai/lmnr' 'README.md' 'lmnr-ai__lmnr.md'
Raw 'comet-ml/opik' 'README.md' 'comet-ml__opik.md'
Raw 'mastra-ai/mastra' 'README.md' 'mastra-ai__mastra.md'
Raw 'agno-agi/agno' 'README.md' 'agno-agi__agno.md'
Raw 'openai/openai-agents-js' 'README.md' 'openai__openai-agents-js.md'
Raw 'QwenLM/Qwen3Guard' 'README.md' 'QwenLM__Qwen3Guard.md'
Raw 'ibm-granite/granite-guardian' 'README.md' 'ibm-granite__granite-guardian.md'
Raw 'openai/codex' 'README.md' 'openai__codex.md'
