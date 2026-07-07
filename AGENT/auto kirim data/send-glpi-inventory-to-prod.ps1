param(
    [string] $Tag = "",
    [switch] $Diagnostic
)

$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "set-glpi-agent-server-and-send.ps1"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Script utama tidak ditemukan: $scriptPath"
}

$arguments = @{
    Server = "https://itpma-ticketing.pinusmerahabadi.co.id/plugins/glpiinventory/"
}

if ($Tag.Trim() -ne "") {
    $arguments.Tag = $Tag.Trim()
}

if ($Diagnostic) {
    $arguments.Diagnostic = $true
}

& $scriptPath @arguments
