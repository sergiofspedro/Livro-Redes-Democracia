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

Write-Host "`n=== Step 3: Copy plugin files (notify + kdco-primitives) ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$configDir\plugins" | Out-Null
Copy-Item ".\global\plugins\*" "$configDir\plugins\" -Recurse -Force

Write-Host "`n=== Step 4: Register the kdco community registry ===" -ForegroundColor Cyan
ocx registry add https://registry.kdco.dev --name kdco -p default

Write-Host "`n=== Step 5: Adopt the default profile under OCX ===" -ForegroundColor Cyan
ocx profile add default --global 2>$null
Copy-Item ".\global\opencode.jsonc" "$configDir\profiles\default\opencode.jsonc" -Force
Copy-Item ".\global\oh-my-openagent.json" "$configDir\profiles\default\oh-my-openagent.json" -Force
New-Item -ItemType Directory -Force -Path "$configDir\profiles\default\plugins" | Out-Null
Copy-Item ".\global\plugins\*" "$configDir\profiles\default\plugins\" -Recurse -Force

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Fully restart OpenCode Desktop now — plugin config is only read at startup." -ForegroundColor Yellow
Write-Host "cc-safety-net and oh-my-openagent are pulled fresh from their registries by OpenCode itself on first launch." -ForegroundColor Yellow
