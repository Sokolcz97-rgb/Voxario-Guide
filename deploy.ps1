$src = "C:\Users\deser\Documents\Github\Voxario-Guide"
$dst = "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\VoxarioGuide"

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
        Copy-Item "$src\$folder\*" "$dst\$folder\" -Recurse -Force
        Write-Host "[SYNC] $folder OK"
    }
}

Write-Host ""
Write-Host "Voxario Guide synchronizovan do WoW."
