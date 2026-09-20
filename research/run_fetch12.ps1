$ErrorActionPreference='Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)
& powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch12.ps1
"### DONE5 ###"
