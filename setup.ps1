# ============================================================
# OpenCode Personal Stack — Restore Script
# Repo: sergiofspedro/Opencode-stack
#
# Prerequisites (do these first, manually):
#   1. Install OpenCode Desktop from opencode.ai
#   2. Install bun:  powershell -c "irm bun.sh/install.ps1 | iex"
#      then restart your terminal (bun needs a fresh session to be on PATH)
#   3. Clone this repo and cd into it:
#        gh repo clone sergiofspedro/Opencode-stack
#        cd Opencode-stack
#   4. Allow script execution for this session:
#        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   5. Run this script:  .\setup.ps1
# ============================================================

$configDir = "$env:USERPROFILE\.config\opencode"

Write-Host "=== Step 1: Install ocx (extension manager) ===" -ForegroundColor Cyan
npm install -g ocx

Write-Host "`n=== Step 2: Copy global config into place ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
Copy-Item ".\global\opencode.jsonc" "$configDir\opencode.jsonc" -Force
Copy-Item ".\global\oh-my-openagent.json" "$configDir\oh-my-openagent.json" -Force
Copy-Item ".\global\package.json" "$configDir\package.json" -Force

Write-Host "`n=== Step 3: Copy agents, skills, commands, tools, plugins ===" -ForegroundColor Cyan
foreach ($sub in @("agents", "skills", "commands", "tools", "plugins")) {
    New-Item -ItemType Directory -Force -Path "$configDir\$sub" | Out-Null
    Copy-Item ".\global\$sub\*" "$configDir\$sub\" -Recurse -Force
}

Write-Host "`n=== Step 4: Install plugin dependencies (envsitter, zod, node-notifier, etc.) ===" -ForegroundColor Cyan
Push-Location $configDir
npm install
Pop-Location

Write-Host "`n=== Step 5: Register the kdco community registry ===" -ForegroundColor Cyan
ocx registry add https://registry.kdco.dev --name kdco -p default

Write-Host "`n=== Step 6: Adopt the default profile under OCX ===" -ForegroundColor Cyan
ocx profile add default --global 2>$null
foreach ($f in @("opencode.jsonc", "oh-my-openagent.json")) {
    Copy-Item ".\global\$f" "$configDir\profiles\default\$f" -Force
}
foreach ($sub in @("agents", "skills", "commands", "tools", "plugins")) {
    New-Item -ItemType Directory -Force -Path "$configDir\profiles\default\$sub" | Out-Null
    Copy-Item ".\global\$sub\*" "$configDir\profiles\default\$sub\" -Recurse -Force
}

Write-Host "`n=== Manual step needed (only if you actually use Firecrawl) ===" -ForegroundColor Yellow
Write-Host "  firecrawl login --browser   OR set FIRECRAWL_API_KEY (firecrawl.dev)"

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Fully restart OpenCode Desktop now — plugin config is only read at startup." -ForegroundColor Yellow
Write-Host "cc-safety-net, oh-my-openagent, opencode-dcp and md-table-formatter are pulled fresh from their registries by OpenCode itself on first launch." -ForegroundColor Yellow
