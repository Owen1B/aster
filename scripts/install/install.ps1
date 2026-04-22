param(
    [string]$Release = "latest"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Error @"
Aster does not currently publish Windows standalone builds.

This fork publishes Linux x86_64 and macOS universal assets on GitHub Releases:
https://github.com/Owen1B/aster/releases/latest

Requested release: $Release
"@
exit 1
