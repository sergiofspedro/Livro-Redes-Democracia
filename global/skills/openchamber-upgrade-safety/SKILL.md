---
description: "Protocolo unificado de upgrade do OpenChamber (LOCAL e VPS pipeline-vps): Fase 0 análise do estado atual, Fase 1 triage + análise da release (OC + opencode bundled + plugins, features/breaking/CVEs), Fase 2 plano de upgrade aprovado + execução + pós-upgrade + rollback com critérios objetivos, Fase 3 monitorização 24-48h + feedback loop. Aplica-se a ambas as instâncias; passos que diferem estão marcados [LOCAL]/[VPS]. Carregar ANTES de qualquer upgrade."
---

# OpenChamber Upgrade Protocol (Local + VPS)

Ritual de 3 fases para upgrades seguros do OpenChamber — local (Windows) e VPS
(pipeline-vps). Cada fase termina com um **output obrigatório** que alimenta a
seguinte. **NUNCA saltar uma fase.**

```
Fase 0 → Estado atual          → inventário snapshot
Fase 1 → Análise da release    → relatório de impacto (features/breaking/CVEs)
Fase 2 → Plano de upgrade      → checklist aprovado pelo dono
      → (executar)             → post-upgrade validation + rollback se falhar
```

---

## FASE 0 — Análise do estado atual

**Objetivo**: inventário completo do que está a correr AGORA, antes de olhar para
qualquer release. Sem isto, a Fase 1 não tem contra o quê comparar.

### 0.1 Versões e binários

**[LOCAL]** `pwsh -File C:\Users\Administrator\.claude\plans\upgrade-baseline.ps1 -Mode pre`
→ guarda snapshot datado em `~\.claude\baselines\openchamber-<ts>\` (12 secções:
OC.exe + opencode.exe sha256/version, configs, processos, portos, disco,
plugins/skills/agents, MCPs, deny list). **Exit 0 = capturado.**

**[VPS]** `docker exec openchamber-openchamber opencode --version` + `docker images` 
(apontar imagem e tag live) + `docker inspect openchamber-openchamber
--format '{{.Image}} {{.Config.Image}}'` + `cat data/opencode/config/opencode.jsonc`
+ overlay `~/.opencode/` (gotcha: comentar no jsonc NÃO basta).

### 0.2 Config efetivamente aplicada (NÃO a fonte)

- **[LOCAL]** `opencode debug config` — verifica parser + config resolvida.
- **[VPS]** `GET /config` do serve (não só o jsonc) — o overlay `~/.opencode/`
  faz MERGE por cima e pode re-injetar plugins que julgávamos removidos.

### 0.3 Inventário de plugins, skills, agents, MCPs, permissões

- Listar plugins ativos/comentados no `opencode.jsonc` + `node_modules/opencode/config/`.
- Listar skills (`ls ~/.config/opencode/skills/` [LOCAL] / `config/skills/` [VPS]).
- Listar agents (orchestrator + subagentes) e os seus modelos.
- Listar MCP servers e respetivos estados de conexão.
- Anotar a **deny list do orchestrator** (contagem — local 74, VPS 73+1).

### 0.4 Estado do runtime

- **[LOCAL]** Processos + RSS (`Get-Process opencode,OpenChamber`), porta 8765
  (router) e porta do serve. **Anotar RSS** — comparar pós-upgrade para detetar
  regressão de memória (baseline 2026-08-31: serve ~900 MB, renderer ~630 MB).
- **[VPS]** `docker compose ps`, `docker stats --no-stream`, `GET /health` do
  router (127.0.0.1:3010 UI; router `http://172.18.0.13:8000/health`), disco do host.
- **Backup datado** (obrigatório, antes de qualquer alteração):
  - [LOCAL] `opencode.jsonc` + `chains.json` + `auth.json` (nomes das chaves só)
  - [VPS] compose + .env + **opencode.jsonc + `data/opencode/auth.json`** + overlay `~/.opencode/`
- **[VPS]** Antes de parar o container: verificar sessões ativas
  (`monitor-opencode-sessions.sh` ou `docker logs openchamber-openchamber --tail 50`)
  — se há sessões vivas, avisar/aguardar paragem limpa antes do upgrade.

**OUTPUT DA FASE 0**: `baseline-<ts>.md` com versões, plugins, agents, MCPs,
deny count, RSS, portos, backup paths. Guardado na pasta do baseline.

---

## FASE 1 — Análise da release nova (OC + opencode + plugins)

**Objetivo**: decidir SE e COMO fazer upgrade, com base na release face ao estado
atual (Fase 0). NUNCA instalar sem passar por esta fase.

### 1.0 Triage de risco (ANTES de analisar)

Determinar o **tipo de release** alvo a partir do semver (tag da Fase 1.1):

| Tipo | Exemplo | Profundidade de análise |
|---|---|---|
| **Patch** | `1.22.0` → `1.22.1` | Checklist curto: changelog + CVEs + `opencode bundled` não mudou. Sem análise profunda de plugins. |
| **Minor** | `1.21.x` → `1.22.0` | Análise completa (1.2 + 1.3): features, breaking, plugins, opencode bundled. |
| **Major** | `1.x` → `2.0` | Análise completa + **plano de migração** dedicado + testar em branch/staging antes. |

### 1.1 Obter releases disponíveis e definir TARGET

- **[LOCAL]** `gh auth status` (se falhar, fallback: `curl -s https://api.github.com/repos/openchamber/openchamber/releases?per_page=10 | jq -r '.[].tag_name'`)
- **[VPS]** `gh auth status` (GH_TOKEN vem do Infisical — **já disponível**, sem fallback curl) + `gh release list --repo openchamber/openchamber --limit 10`
- Determinar **TARGET** = `max(tag semver > versão atual)`. Se houver múltiplas releases desde a minha versão, comparar contra a **mais recente** (não a primeira depois da minha). Upgrade direto = salta releases intermédias — validar migração acumulada no changelog.

### 1.2 Análise da release TARGET (definida em 1.1)

| Check | Comando/Fonte |
|---|---|
| Tag + data | `gh release view <tag>` |
| Changelog | `gh release view <tag> --json body` — **ler todo o body** |
| Assets + SHA | `gh release view <tag> --json assets` — verificar SHA-256 do installer [LOCAL] / imagem [VPS] |
| Breaking changes | `grep -i 'breaking\|deprecat\|removed\|migration'` no changelog |
| CVEs | `gh release view <tag> --json body \| grep -i 'cve\|security\|vuln'` |
| **Bump do opencode bundled** | Inspecionar a release ANTES de instalar: assets do release (nome/versão do `opencode.exe`/binário) ou `git show <tag>:package.json` do repo (campo de dependência). Na v1.22.0 descobrimos o bump 1.18.18→1.18.25 SÓ DEPOIS de instalar — evitar repetir. |

### 1.3 Análise de impacto (face à Fase 0)

| Item | Pergunta | Onde verificar |
|---|---|---|
| **opencode bundled** | A release bumpa o `opencode.exe` CLI? Se sim, o bump do SDK (`@opencode-ai/sdk`) pode quebrar plugins que usam a API | changelog + `package.json` do tag + plugins no meu config |
| **Plugins** | Os plugins que uso (open-mem, plannotator, open-controller, auto-resume) são compatíveis? | release notes do plugin + issues abertas |
| **Config keys** | `chunkTimeoutMs`, `compaction.auto`, `default_agent`, permissões, `instructions` array — mudaram nomes/defaults? | changelog + `GET /config` pós-upgrade |
| **Features novas** | O que ganho? (ex.: v1.22.0 = Linear, multi-repo git, themes) | changelog body |
| **Custos/risco** | Bump minor/patch? Requer rebuild de imagem [VPS]? Requer reinstall NSIS [LOCAL]? | tag semantics + Dockerfile |

### 1.4 Decisão

- **UPGRADE** — features valem o risco, plugins compatíveis.
- **SKIP** — sem features relevantes, ou breaking incomportável agora.
- **HOLD** — precisa de investigação extra (ex.: plugin X ainda não suporta).

Registar a decisão E o rationale no `baseline-<ts>.md` (ou release notes).

**OUTPUT DA FASE 1**: `release-impact-<tag>.md` — tabela features/breaking/CVEs,
compatibilidade de plugins, decisão + rationale.

---

## FASE 2 — Plano de upgrade

**Objetivo**: checklist operacional pré-aprovado pelo dono. NUNCA executar sem
aprovação explícita (regra #67/#70 — plano → aprovação → execução).

### 2.1 Preparação

- [ ] Backup datado (Fase 0.4) confirmado
- [ ] Baseline pre (Fase 0.1) confirmado
- [ ] **[VPS]** Sessões ativas verificadas (Fase 0.4) — sem sessões vivas ou dono avisado
- [ ] **Fechar OpenChamber** [LOCAL] / **parar container** [VPS]
- [ ] Verificar disco [LOCAL] ≥10 GB / [VPS] ≥5 GB
- [ ] Anotar PIDs/containers atuais (rollback reference)

### 2.2 Execução

**[LOCAL]**
1. Descarregar installer oficial (URL do GitHub, SHA-256 validado contra 1.2)
2. Instalar (NSIS) — fecha o OpenChamber, mata a sessão
3. Reabrir OpenChamber

**[VPS]**
1. `cd /home/pipeline/pipeline/docker/openchamber && git fetch origin`
2. Criar branch `upgrade-v<versao>` a partir do tag
3. Merge dos patches locais preservados (obrigatório):
   - **Dockerfile**: RTK/fdx/gh/cloudflared/serena + pin `opencode-ai@<versão do SDK>`
   - **lifecycle.js**: timeout 90s
   - **opencode.jsonc**: anotar patches open-mem@0.14.2 (MD5 em comentário)
4. `docker compose up -d --build`
5. **Timeout MCP -32001 em builds longos NÃO significa falha** — verificar via
   `/tmp/build_v<versao>.log` ou `docker images` (ID novo), nunca re-correr às cegas

### 2.3 Pós-upgrade (validation obrigatória)

- [ ] `upgrade-baseline.ps1 -Mode post` [LOCAL] → diff, exit 1 se mudou
      / [VPS] `docker compose ps` + `docker images` (ID novo) + logs
- [ ] Versão OpenChamber + opencode bundled corretos
- [ ] `GET /config` (config efetivamente aplicada — overlay VPS!)
- [ ] MCP servers conectados (sem "failed"/"disconnected")
- [ ] Router: [LOCAL] porta 8765 UP / [VPS] `/health` + request real
- [ ] Smoke test: 1 mensagem a modelo, resposta normal
- [ ] Subagentes com tools esperados (`opencode debug agent <nome>`)
- [ ] **RSS comparado com a Fase 0.4** — regressão de memória = red flag
- [ ] **`PRAGMA integrity_check`** no opencode.db [LOCAL: OC fechado / VPS: backup weekly]
      — confirmar que o upgrade não corrompeu a DB
- [ ] AGENTS.md carregado (system prompt contém o esperado)
- [ ] **A UI DESENHA** — nao basta HTTP 200. Abrir a interface num browser e confirmar
      que ha *layout*: barras, paineis, espacamento. Um 200 diz que o servidor responde,
      nao que a aplicacao e usavel.
- [ ] **CSS com classes utilitarias** (2 segundos, apanha o caso acima sem browser):
      `curl -s <url>/assets/index-*.css | grep -c '\.flex{'`
      Zero em `.flex{`, `.grid{`, `.w-full{` = folha de estilos sem utilitarias.
      Medido a 2026-08-31 no upgrade v1.19.0 -> v1.22.0: 584 variaveis de tema presentes
      e ZERO utilitarias. A UI aparecia como HTML cru -- conteudo todo correcto, layout
      nenhum -- e **passou nas oito validacoes existentes**, porque todas mediam HTTP,
      versoes e processos. Nenhuma olhava para o ecra.
- [ ] **Consola do browser sem erros** ao carregar a UI (F12 -> Console).
      Verificar tambem no separador Network que o CSS e pedido e chega a 200.

### 2.3b Release notes (template obrigatório)

Após validação, escrever release notes num formato fixo (ficheiro por upgrade):

```md
# <Componente> <versão_nova> — Release & Upgrade Notes (<data>)

## Versão anterior → nova
- OpenChamber: <antes> → <depois>
- opencode bundled: <antes> → <depois> (se mudou)
- Plugins: <lista com versões antes/depois se mudaram>

## Features ganhas
- <feature 1>
- <feature 2>

## Breaking changes / migrações
- <item> (ação tomada)

## CVEs / security
- <item> (ação tomada)

## Ações pós-upgrade
- <item (ex.: router restart, re-pin plugin, ajuste config)>

## Lições / próximos passos
- <lição da Fase 3, se aplicável>
```

### 2.3c Inspeccionar a imagem ANTES de recriar o container (2026-09-01)

Construir e trocar sao passos separados. `docker compose build` nao mexe no que esta a correr:
usar essa janela para verificar a imagem nova por dentro, e so recriar se passar.

```sh
docker compose build openchamber          # nao toca no container a correr
docker run --rm --entrypoint sh <img> -c '
  f=$(find / -path "*dist*/assets/index-*.css" | head -1)
  echo "$f  $(wc -c < "$f") bytes"
  for c in ".flex{" ".grid{" ".w-full{"; do echo "$c -> $(grep -oF "$c" "$f" | wc -l)"; done'
```

Salvou uma troca ma a 2026-09-01: a imagem reconstruida continuava sem utilitarias, viu-se antes
de a por a servir, e o dono nunca ficou sem interface.

Guardar sempre a imagem partida com etiqueta propria antes de reverter
(`docker tag <repo>:latest <repo>:1.22.0-css-partido`) — e o material de prova para a issue e
para quando o upstream pedir mais informacao.

### 2.3d `docker compose up -d` NAO reinicia um container que ja corre

Armadilha que custou uma hora a 2026-08-31. O `start-openchamber.sh` corre `compose up -d`; se o
container ja estiver de pe, o compose reporta `Container openchamber Running` e nao faz nada. As
verificacoes do script correm todas e dao verde, o que torna a saida enganadora: parece um
arranque bem-sucedido e nao houve arranque nenhum.

Para reiniciar mesmo: `docker restart openchamber`, ou `compose up -d --force-recreate`.
Confirmar pelo StartedAt, nunca pela mensagem do script:

```sh
docker inspect openchamber --format '{{.State.StartedAt}} restarts={{.RestartCount}}'
```

### 2.4 Rollback

**Verificar o alvo ANTES de reverter.** Um rollback so vale se a imagem antiga estiver mesmo boa:
correr nela a mesma verificacao da Fase 2.3 (CSS com utilitarias, `/api/config` 200) antes de a
promover a `latest`. A 2026-09-01 confirmou-se `v1.19.0 = 275.596 bytes com .flex/.grid/.w-full
presentes` contra `v1.22.0 = 134.510 bytes com tudo a zero` — a diferenca provou que a regressao
era do build e nao do ambiente, e foi o corpo da issue openchamber/openchamber#3282.

**Issues abertas neste ciclo**, referencia para o proximo upgrade: #3282 (CSS sem utilitarias),
#3283 (`POST /api/auth/login` devolve 401, login impossivel), #3284 (postinstall parte o build
Docker, com correccao proposta).

**Critérios objetivos de rollback** (se QUALQUER um se verificar, fazer rollback sem
esperar aprovação — a máquina deve ficar num estado conhecido):

- [ ] Smoke test falhou (mensagem a modelo não responde)
- [ ] MCPs em estado "failed"/"disconnected" (não resolvível com restart)
- [ ] RSS do serve > 2× o baseline da Fase 0.4 (regressão de memória)
- [ ] Logs com erros novos e repetidos (não apenas warnings transitórios)
- [ ] `opencode.db` com erros de integridade (ver Fase 2.3 `PRAGMA integrity_check`)
- [ ] Config efetiva (`GET /config`) não corresponde ao esperado

**[LOCAL]** Restaurar config do backup datado; reinstalar NSIS anterior se binário
partiu; reabrir + verificar versão. Rollback = "instalar versão anterior sobre a atual".

**[VPS]** `docker compose up -d` com a tag anterior (ex.: `1.18.3-pre-v119`). Overlay
`~/.opencode/` NÃO está no backup semanal — restaurar do backup manual.

---

## FASE 3 — Pós-upgrade (monitorização)

Após o upgrade, nas 24-48h seguintes, verificar:
- RSS do serve [LOCAL] (baseline ~900 MB) — não disparar
- [VPS] `monitor-resources.sh` não alarma; disk <85%; RAM avail >2 GiB
- Logs sem erros novos (`opencode.log` [LOCAL] / `docker logs` [VPS])
- `opencode.db` não cresceu anormalmente (backup weekly [VPS], VACUUM mensal [LOCAL])

**Feedback loop (fechar o ciclo)**:
- Se a Fase 3 encontrar algo (regressão tardia, plugin partido, DB estranha) → registar
  no release notes (secção "Lições") + criar/atualizar memória durável (open-mem).
- Se correu limpo → atualizar a linha de baseline no `openchamber-vps` / AGENTS.md
  (ex.: "estado atual 2026-08-29 → 2026-09-XX") para que a PRÓXIMA Fase 0 tenha
  valores corretos.
- **Não arquivar a skill de upgrade até a Fase 3 passar** — é a janela de deteção de
  regressões silenciosas (RSS, disco, DB).

---

## Gotchas (LOCAL e VPS)

- **`windows-mcp_*` deny no orchestrator** é by design desde 2026-08-19; a tool está
  disponível em subagentes (`explore`). Não é regressão.
- **Plugin pins** — `npm @latest` pode partir. Manter pins (ex.: `@plannotator/opencode@0.23.1`).
- **`chunkTimeoutMs`** — default 45s. Se raised (300000 [LOCAL] / 600000 [VPS]),
  confirmar que sobreviveu ao upgrade.
- **chains.json lido UMA vez no arranque** do router — alterações exigem restart.
- **overlay `~/.opencode/`** [VPS] — comentar plugin no jsonc NÃO o remove se
  também estiver no overlay. Verificar `GET /config`.
- **`auth.json` nunca imprimir valor** — copiar ficheiro é seguro, imprimir não.
- **Timeout MCP -32001** em builds longos NÃO é falha — verificar estado real.
- **O `postinstall` do monorepo precisa de ficheiros que a fase `deps` nao copiava**
  (descoberto 2026-09-01). Ele corre
  `node ./fix-deprecation.js && patch-package && ensure-electron.mjs --best-effort`,
  e o Dockerfile so copiava os `package.json` e o lockfile. Falhava com
  `Module not found '/app/fix-deprecation.js'`, depois com o `ensure-electron.mjs`.
  O `--best-effort` nao salva: o node falha por o modulo nao existir, antes de a bandeira
  contar. Corrigido copiando `fix-deprecation.js`, `patches/` e `packages/electron/scripts`.

## Anti-patterns (NUNCA)

- Não saltar fases; não instalar release sem Fase 1 (impacto analisado).
- Não reler ficheiros múltiplas vezes (token waste) — reusar output em contexto.
- Não usar `bash` no Windows [LOCAL] — deny; usar `pc-exec`.
- Não correr `git log` em pty sem `--no-pager` [VPS] — fica preso.
- Não passar `label` como string a `docker_list_containers` — espera list.
- Não fazer heredoc via SSH [VPS] — `${VAR}` e aspas partem; script local + scp + remoto.
- Não editar workspace file e usar CLI/agent no mesmo file antes de restart [VPS].
- **Nunca resolver um script partido com um remendo que desliga uma categoria inteira**
  — e se for inevitavel, escrever ali porque, e o que se perde. O `bun install` corria com
  `--ignore-scripts` para contornar UM `postinstall` partido, e isso desligava TODOS os
  scripts de pos-instalacao do projecto. Ninguem sabia disso meses depois, e passou a ser
  o primeiro suspeito de qualquer coisa que faltasse no build. Um remendo sem a razao
  escrita ao lado transforma-se em folclore: toda a gente tem medo de lhe tocar e ninguem
  sabe o que ele protege.
- **Nunca declarar um upgrade validado sem ter olhado para o ecra.** Ver Fase 2.3: oito
  verificacoes de HTTP, versoes e processos deram PASS com a UI completamente partida.

## Referências

- **[LOCAL]** `upgrade-baseline.ps1` em `~\.claude\plans\` (baseline pre/post)
- **[VPS]** Secção "Atualizar o OpenChamber VPS" da skill `openchamber-vps`
  (procedimento verificado v1.19.0) + `openchamber-config-surgery` (edits config)
- **[VPS]** `vps-service-debug` (logs verdadeiros, SQLite WAL, PIDs host vs container)
- Release notes locais: `~\.claude\notes\RELEASE-NOTES-20260831-OC1.22.0-upgrade.md`
