$ErrorActionPreference='Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)
& powershell -NoProfile -ExecutionPolicy Bypass -File research/fetch10.ps1
"### DONE3 ###"
