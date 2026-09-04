---
name: vps-general
description: Gestão geral do VPS pipeline-vps (Hostinger KVM4, Tailscale) — inventário de containers, redes, segurança, disk, Infisical, lições operacionais do runbook. Usar para qualquer operação no VPS que não seja OpenClaw/n8n/OpenWebUI/OpenChamber especificamente.
---

# VPS General — Gestão Geral do pipeline-vps

Manual de operação geral do VPS **pipeline-vps** (Hostinger KVM4, `pipeline@100.95.67.86` via Tailscale). Conhecimento absorvido do Claude Code (`memory/vps/vps.md` + `runbook.md` + `hostinger-kvm4-migration.md`) e verificado contra a máquina 2026-08-19.

## Estado atual (2026-08-19)

**Acesso**: SSH `pipeline@100.95.67.86` (Tailscale). Alias `pipeline-vps` no `~/.ssh/config`.
**Host**: Hostinger KVM4, 38 GB disco (~80-94% livre), Tailscale.

## Inventário de containers (27 verificados 2026-08-19)

| Container | Imagem | Porta (host) | Rede |
|---|---|---|---|
| openchamber | openchamber-openchamber (v1.19.0) | 127.0.0.1:3010→3000 | infisical_pipeline-net |
| openclaw | ghcr.io/openclaw/openclaw:2026.6.11 | 100.95.67.86:7000→7000, 127.0.0.1:18789→18789 | infisical_pipeline-net + n8n_default |
| n8n | n8nio/n8n:2.31.6 | 127.0.0.1:5678 | n8n_default |
| open-webui | open-webui-custom:latest | 127.0.0.1:8082→8080 | infisical_pipeline-net |
| opencode-fallback-proxy | opencode-fallback-proxy:latest | 8000 (interno) | infisical_pipeline-net |
| infisical + postgres + redis | infisical/infisical:latest etc | 127.0.0.1:8080→8080 | infisical_pipeline-net |
| grafana | grafana/grafana-oss:latest | 100.95.67.86:3000→3000 | — |
| loki + promtail | grafana/loki + promtail | 127.0.0.1:3100→3100 | loki_monitoring-net |
| uptime-kuma | louislam/uptime-kuma:2 | 127.0.0.1:3001→3001 | uptime-kuma_default |
| freshrss | freshrss/freshrss:latest | 100.95.67.86:8081→80 | — |
| searxng | searxng/searxng | 127.0.0.1:8889→8080 | — |
| qdrant | qdrant/qdrant:latest | 127.0.0.1:6333-6334 | — |
| firecrawl-* (playwright, postgres, rabbitmq, redis) | firecrawl stack | internas | firecrawl_firecrawl-net |
| searcrawl_app + searcrawl_redis | tavily-open-app | **0.0.0.0:8000→3000, 0.0.0.0:6379→6379** | tavily-open_default |
| byparr | ghcr.io/thephaseless/byparr:latest | 127.0.0.1:8191 | — |
| filebrowser | gtstef/filebrowser:latest | 127.0.0.1:8083→80 | — |
| parakeet | ghcr.io/achetronic/parakeet:latest | 127.0.0.1:9000→5092 | — |
| obsidian-embedder | obsidian-embedder:latest | 8500 | — |
| intel-graph | intel-graph:latest | 8600 | — |

⚠️ **Segurança — 2 containers expostos em 0.0.0.0**: `searcrawl_app` (8000) e **`searcrawl_redis` (6379 — Redis público!)**. O resto do stack está em loopback/Tailscale. Recomendado: verificar se o searcrawl precisa mesmo de exposição pública; se não, bind a loopback.

## Redes
`bridge`, `firecrawl_firecrawl-net`, `host`, `infisical_pipeline-net`, `loki_monitoring-net`, `n8n_default`, `tavily-open_default`, `uptime-kuma_default`, `none`

## Segurança (vps.md)
- **Fail2ban ativo** (SSH jail via defaults-debian.conf; `sudo` necessário para query status — não é falha)
- **SSH bound a Tailscale apenas**: `100.87.152.63:2222` — IP público NÃO aceita SSH (`/etc/systemd/system/ssh.socket.d/override.conf`, belt-and-suspenders no `sshd_config` linha 134)
- **Hermes dashboard Tailscale-only**: `100.87.152.63:9120` (era 0.0.0.0, corrigido)
- **Sem plain-text secrets em disco** — tudo via Infisical
- Unattended-upgrades ativo (patches de segurança auto)
- Policy check: `docker exec openclaw openclaw policy check` (39 checks, 0 findings)
- **Sudo sem password APENAS para**: `docker ps`, `docker exec`, `docker compose`, `fail2ban-client status`. `apt-get`/`apt upgrade` NÃO está na allowlist (Gio corre manualmente)
- **OpenClaw `/run/secrets/` partilhado entre agentes** (Agent Vault ainda pendente) — mitigado com per-agent tools policy em `openclaw.json`

## Disk — pitfalls conhecidos (2026-07-11)
- **Upgrade `docker-ce` reinicia o daemon → containers SEM restart policy caem** (openclaw, n8n, civicconnect-demo-*). Depois de upgrade docker-ce, verificar `docker ps -a` e reiniciar openclaw (`start-openclaw.sh`) e n8n (`start-n8n.sh`) se preciso
- **Backup-of-backups bug** (fix 2026-07-11): nunca deixar um bind-mount de container conter o output do próprio backup periódico — duplicou disco diariamente (70MB→1.19GB em 4 dias). Backups do OpenClaw agora em `/home/pipeline/pipeline/backups/` (fora de mounts)
- Quick wins quando disco aperta: `npm cache clean --force`, `~/.cache/{ms-playwright,pip,electron}`, snapshots datados em `/home/pipeline/` (300-900 MB, seguros de apagar se superseded)

## Infisical
- Projeto `bdec46df-…`, env prod, universal auth
- Credenciais: `/home/pipeline/.infisical-credentials`
- Secrets refresh: `bash /home/pipeline/pipeline/scripts/refresh-secrets.sh`
- **Nunca colar chaves no chat** (regra #71/#78) — via Infisical ou push-cc-key.sh

## Scripts de arranque
- `start-openclaw.sh`, `start-n8n.sh`, `start-opencode-fallback-proxy.sh` (rebuild do proxy com chaves do Infisical — **nunca `docker compose up` direto**, não carrega chaves)
- `push-cc-key.sh`, `refresh-secrets.sh`

## Lições operacionais (runbook — gerais)
- `docker compose up` direto num serviço com `${VAR}` no compose **não carrega chaves** se o dir não tem `.env` — usar o start script que exporta do Infisical
- Checkpoint WAL periódico (db-maintenance.sh, cron 0 3 * * *) — WAL gigante degrada queries (367 MB VPS / 854 MB local encontrados)
- Verificar estado real via `docker ps`/logs, nunca assumir falha de timeout MCP (-32001) como falha real

## Key File Paths
- Containers: `/home/pipeline/pipeline/docker/<nome>/`
- Scripts: `/home/pipeline/pipeline/scripts/`
- Logs: `/home/pipeline/pipeline/logs/`
- Backups OpenClaw: `/home/pipeline/pipeline/backups/`
- Credenciais Infisical: `/home/pipeline/.infisical-credentials`

## Path mapping (container ↔ host) — added 2026-09-04

OpenChamber runs **inside a container**, but the user can also `docker exec` into it. Path confusion between container-internal and host-bind-mount paths wastes minutes every noites M0 (real example: `ses_f96b45f0cffedj1m4dihINdUlH`, 348s lost).

**Rule: in briefs, scripts, and reports, ALWAYS cite the path for the side that reads it.** Container paths in container-issued commands and briefs; host paths in compose files, `docker exec` arguments, and host cron jobs.

| Container path (inside `docker exec openchamber bash`) | Host path (on `pipeline-vps`) |
|---|---|
| `/home/openchamber/workspaces/<project>/` | `/home/pipeline/pipeline/docker/openchamber/workspaces/<project>/` |
| `/home/openchamber/workspaces/<project>/app/` | `/home/pipeline/pipeline/docker/openchamber/workspaces/<project>/app/` |
| `/home/openchamber/.config/opencode/` | `/home/pipeline/pipeline/docker/openchamber/data/opencode/config/` |
| `/home/openchamber/.local/share/opencode/opencode.db` | bind mount — **never copy live**; use `sqlite3.Connection.backup()` |
| `/home/openchamber/.open-mem/memory.db` | bind mount — schema varies, see AGENTS.md §memory |
| `/run/secrets/active.env` | tmpfs-only (no host equivalent) — sourced by sidecar at boot |
| `/home/openchamber/.config/opencode/agents/` | `/home/pipeline/pipeline/docker/openchamber/data/opencode/config/agents/` |

**Test for "which side am I on?":**
- If your command starts with `docker exec`, you're on the **host**. The argument to the next command is the **container** path.
- If your command is `docker exec openchamber ...`, then everything inside `...` is **container** territory.
- `pwd` inside the container = `/home/openchamber/workspaces/<project>/app` (default). On the host, same content lives under the host path.

**Examples:**
- Wrong: `cat /home/pipeline/pipeline/docker/openchamber/workspaces/...` from inside the container.
- Right: from inside container, `cat /home/openchamber/workspaces/...`; from host, `cat /home/pipeline/pipeline/docker/openchamber/workspaces/...`.
- For the opencode DB: from host, `docker exec openchamber python3 -c "import sqlite3; ..."` (operate inside the container). Never `cp /home/pipeline/.../opencode.db ...` on the host while OC is running.

**Skill `prompt-noite-builder` (M0 Pre-flight)** runs this exact check before step 1 — see that skill for the per-session protocol.

### Gotcha: two `Dashboard project` dirs (one uppercase, one lowercase)

`workspaces/` contains BOTH `Dashboard project` (uppercase D, mtime Sep 4 04:53, **the live one**) and `dashboard project` (lowercase, mtime Aug 31, **legacy**, ~1.5 KB — empty project). `ls -la` sorts them adjacent and they're visually almost identical in monochrome logs.

- **Always use `Dashboard project`** (uppercase D) in briefs and scripts.
- The lowercase `dashboard project` is an old artifact from before the rename. Do not write to it. Safe to archive to `backups/dashboard-legacy-<date>/` if you want, but **not required**.
- Inside the container, the bind mount maps both correctly (`/home/openchamber/workspaces/Dashboard project` ↔ `/home/pipeline/pipeline/docker/openchamber/workspaces/Dashboard project`).

**Verify with:** `ls -la /home/pipeline/pipeline/docker/openchamber/workspaces/ | grep -i dashboard` — expect 2 lines. The uppercase one should have the most recent mtime.

Última atualização: 2026-08-19 (criado do vps.md + runbook.md do Claude Code + verificação real)
