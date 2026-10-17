param(
    [string]$Target = "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\VoxarioGuide"
)

$ErrorActionPreference = "Stop"
# Zdroj je vždy složka VoxarioGuide vedle tohoto skriptu (ne natvrdo cesta jednoho PC).
$src = Join-Path $PSScriptRoot "VoxarioGuide"
$dst = $Target
if (-not (Test-Path (Join-Path $src "VoxarioGuide.toc"))) { throw "Source addon not found: $src" }

New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item "$src\VoxarioGuide.toc" "$dst\VoxarioGuide.toc" -Force

$folders = @(
    "Core",
    "Data",
    "Guides",
    "Localization",
    "UI"
)

foreach ($folder in $folders) {
    if (Test-Path "$src\$folder") {
        New-Item -ItemType Directory -Force -Path "$dst\$folder" | Out-Null
        Copy-Item "$src\$folder\*" "$dst\$folder\" -Recurse -Force
        Write-Host "[SYNC] $folder OK"
    }
}

$sourceVersion = (Select-String -Path "$src\VoxarioGuide.toc" -Pattern '^## Version:' | Select-Object -First 1).Line
$targetVersion = (Select-String -Path "$dst\VoxarioGuide.toc" -Pattern '^## Version:' | Select-Object -First 1).Line
$required = @("VoxarioGuide.toc", "Data\Generated\Zones.lua", "Data\Generated\Quests.lua", "Data\Generated\NPCs.lua", "Data\Generated\Items.lua")
foreach ($relative in $required) {
    $sourceFile = Join-Path $src $relative; $targetFile = Join-Path $dst $relative
    if (-not (Test-Path $targetFile)) { throw "Deployment failed: missing destination $relative" }
    if ((Get-Item $sourceFile).Length -ne (Get-Item $targetFile).Length) { throw "Deployment failed: size mismatch $relative" }
    Write-Host "[VERIFY] $relative OK ($((Get-Item $targetFile).Length) bytes)"
}
if ($sourceVersion -ne $targetVersion) { throw "Deployment failed: TOC version mismatch" }
Write-Host "[VERIFY] TOC version OK: $targetVersion"
Write-Host "Voxario Guide synchronized to WoW."
