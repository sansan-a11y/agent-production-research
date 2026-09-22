$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/128 Safari/537.36'
function Arxiv($label, $query) {
  $u = "http://export.arxiv.org/api/query?search_query=" + [uri]::EscapeDataString($query) + "&start=0&max_results=4&sortBy=relevance"
  "`n=== $label :: $query ==="
  try {
    $x = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 45 -Headers @{'User-Agent'=$UA}).Content
    $ms = [regex]::Matches($x, '(?s)<entry>(.*?)</entry>')
    if ($ms.Count -eq 0) { "  no entries"; return }
    foreach ($m in $ms) {
      $e = $m.Groups[1].Value
      $ti = ($e -replace '(?s).*?<title>(.*?)</title>.*', '$1')
      $ti = ([regex]::Match($e,'(?s)<title>(.*?)</title>').Groups[1].Value -replace '\s+',' ').Trim()
      $id = [regex]::Match($e,'(?s)<id>(.*?)</id>').Groups[1].Value
      $pu = [regex]::Match($e,'(?s)<published>(.*?)</published>').Groups[1].Value
      $su = ([regex]::Match($e,'(?s)<summary>(.*?)</summary>').Groups[1].Value -replace '\s+',' ').Trim()
      if ($su.Length -gt 700) { $su = $su.Substring(0,700) }
      "  - [$(($id -split '/abs/')[-1])] $ti  (pub=$($pu.Substring(0,10)))"
      "    $su"
    }
  } catch { "  ERR: $($_.Exception.Message)" }
  Start-Sleep -Seconds 3
}
"===== ROUND5 ARXIV (survey scan) ====="
Arxiv 'survey-agent-eval' 'ti:"survey" AND abs:"evaluation" AND abs:"LLM agents"'
Arxiv 'survey-llm-judge' 'ti:"survey" AND abs:"LLM-as-a-judge"'
Arxiv 'survey-hitl-deferral' 'abs:"human-in-the-loop" AND abs:"survey" AND abs:"large language models"'
Arxiv 'survey-uncertainty-llm' 'ti:"survey" AND abs:"uncertainty" AND abs:"large language models"'
Arxiv 'trace-to-trust' 'ti:"From Agent Traces to Trust"'
Arxiv 'survey-routing-cascade' 'ti:"Dynamic Model Routing and Cascading"'
Arxiv 'survey-prod-monitoring-llm' 'abs:"production" AND abs:"monitoring" AND abs:"survey" AND abs:"LLM applications"'
"### ROUND5 DONE ###"
