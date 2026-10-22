# Join the MatrixHunter 1.0.6 installer parts.
# Gitee limits a single repository file to 50 MB, so the MSI is split into 3 parts.
# Run this script from the dist directory:
#   powershell -ExecutionPolicy Bypass -File .\join-installer.ps1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$dir = $PSScriptRoot
$out = Join-Path $dir "MatrixHunter-1.0.6.msi"
$expectedSize = 108724224
$expectedHash = "D002E1E97AE33F3949D69531D7804543E9A879262362F8C80656AA2A7F908FB0"

$parts = @(Get-ChildItem -Path $dir -Filter "MatrixHunter-1.0.6.msi.part*" | Sort-Object Name)
if ($parts.Count -ne 3) {
    throw "Expected 3 parts, found $($parts.Count). Please download all part files."
}

$total = ($parts | Measure-Object -Property Length -Sum).Sum
if ($total -ne $expectedSize) {
    throw "Part size mismatch: $total bytes (expected $expectedSize). Please re-download the parts."
}

if (Test-Path $out) {
    Remove-Item $out -Force
}

$fs = [System.IO.File]::Open($out, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
try {
    foreach ($p in $parts) {
        $in = [System.IO.File]::OpenRead($p.FullName)
        try {
            $in.CopyTo($fs)
        } finally {
            $in.Dispose()
        }
    }
} finally {
    $fs.Dispose()
}

$actual = (Get-FileHash -Path $out -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actual -ne $expectedHash) {
    throw "SHA256 mismatch: $actual (expected $expectedHash). The joined file is corrupted."
}

Write-Host "Created: $out"
Write-Host "Size:    $expectedSize bytes"
Write-Host "SHA256:  $actual"
