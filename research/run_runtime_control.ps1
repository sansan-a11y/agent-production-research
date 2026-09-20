$ErrorActionPreference='Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)
"### fetch6 (vendor docs) ###";  & powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch6.ps1
"### fetch7 (repo READMEs) ###"; & powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch7.ps1
"### meta4 (stars/release) ###"; & powershell -NoProfile -ExecutionPolicy Bypass -File research/meta4.ps1
"### meta3 (metadata) ###";      & powershell -NoProfile -ExecutionPolicy Bypass -File research/meta3.ps1
"### gh_scan_guard (discovery) ###"; & powershell -NoProfile -ExecutionPolicy Bypass -File research/gh_scan_guard.ps1
"### ALL DONE ###"
