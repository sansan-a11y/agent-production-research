$ErrorActionPreference='Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)
"### fetch8 ###"; & powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch8.ps1
"### fetch9 ###"; & powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch9.ps1
"### meta5 ###"; & powershell -NoProfile -ExecutionPolicy Bypass -File research/meta5.ps1
"### DONE2 ###"
