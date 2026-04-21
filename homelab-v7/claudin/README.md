# Claudin — Agente Claude Code Autônomo

Agente autônomo que recebe comandos via Discord, executa tarefas no projeto continuamente e reporta status de volta ao canal.

> **IMPORTANTE:** Claude Code Channels **não funciona com `ANTHROPIC_API_KEY`**.
> Requer login via CLI: `claude login` (conta claude.ai).

---

## Estrutura

```
claudin/
├── CLAUDE.md                    # Instruções do agente (loop de trabalho, regras, detecção de loop)
├── .env.example                 # Template de variáveis de ambiente
├── .mcp.json                    # Configuração do MCP server Discord
├── .gitignore                   # Ignora .env e arquivos de runtime
│
├── channels/
│   └── discord-mcp.ts           # MCP server — expõe send_to_discord e send_heartbeat
│
├── settings/
│   └── settings.json            # Settings do Claude Code (bypassPermissions + hooks)
│
├── hooks/
│   └── post-tool.sh             # Hook pós-execução (atualiza timestamp de atividade)
│
├── health/
│   ├── heartbeat.sh             # Sinal de vida — ping healthchecks.io + atualiza arquivo local
│   ├── watchdog.sh              # Verifica se agente está vivo — alerta se parou > 10 min
│   └── startup-notify.sh        # Notifica Discord quando o serviço inicia
│
├── systemd/
│   ├── claudin-agent.service    # Serviço principal do agente
│   ├── claudin-watchdog.service # Serviço do watchdog (oneshot)
│   └── claudin-watchdog.timer   # Timer do watchdog (a cada 5 min)
│
├── tasks/
│   └── backlog.md               # Fila de tarefas do agente
│
├── scripts/
│   ├── install.sh               # Instalação completa
│   ├── setup-ssh.sh             # Configura chave SSH para Git
│   └── start.sh                 # Inicia manualmente (sem systemd)
│
└── docs/
    └── architecture.md          # Diagrama da estratégia de health check
```

---

## Setup Rápido (Raspberry Pi)

### 1. Pré-requisitos

```bash
# Instalar Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Fazer login (OBRIGATÓRIO — Channels não funciona com API key)
claude login

# Instalar Bun
curl -fsSL https://bun.sh/install | bash
```

### 2. Configurar variáveis de ambiente

```bash
cp claudin/.env.example claudin/.env
nano claudin/.env
```

Preencha obrigatoriamente:
- `DISCORD_BOT_TOKEN` — token do bot (Discord Developer Portal)
- `DISCORD_WEBHOOK_URL` — webhook do canal de alertas
- `SSH_KEY_PATH` — caminho da chave SSH para Git

### 3. Configurar SSH para Git

```bash
bash claudin/scripts/setup-ssh.sh
# Siga as instruções para adicionar a chave pública ao GitHub
```

### 4. Configurar Discord Bot

1. Acesse [Discord Developer Portal](https://discord.com/developers/applications)
2. Crie um novo Application → Bot
3. Copie o token para `.env`
4. Habilite **Message Content Intent** nas configurações do bot
5. Convide o bot com permissões: View Channels, Send Messages, Read History

### 5. Instalação completa

```bash
bash claudin/scripts/install.sh
```

### 6. Instalar plugin Discord no Claude Code

Em uma sessão interativa do `claude`:
```
/plugin install discord@claude-plugins-official
/discord:configure SEU_BOT_TOKEN_AQUI
/discord:access policy allowlist
```

### 7. Configurar healthchecks.io (detecção de queda da máquina)

1. Crie conta em [healthchecks.io](https://healthchecks.io) (free tier)
2. Crie um check: Period = **5 min**, Grace = **5 min**
3. Configure integração com Discord no healthchecks.io
4. Adicione a ping URL no `.env`: `HEALTHCHECK_PING_URL=https://hc-ping.com/SEU-UUID`

### 8. Copiar settings do Claude Code

```bash
cp claudin/settings/settings.json ~/.claude/settings.json
```

### 9. Iniciar serviços

```bash
sudo systemctl start claudin-agent
sudo systemctl start claudin-watchdog.timer

# Verificar logs
journalctl -u claudin-agent -f
```

---

## Como adicionar tarefas

Edite `claudin/tasks/backlog.md` diretamente, ou envie mensagem no Discord:

```
!task Implementar autenticação JWT | alta
```

O agente vai processar as tarefas de cima para baixo e reportar o progresso no canal.

---

## Alertas que você vai receber no Discord

| Situação | Emoji | Quem envia |
|----------|-------|-----------|
| Agente iniciou | 🤖 | startup-notify.sh |
| Tarefa concluída | ✅ | Agente |
| Agente travado/loop | 🆘 | Agente |
| Sem tarefas | 💤 | Agente |
| Precisa de decisão | ❓ | Agente |
| Agente parou (watchdog) | 🚨 | watchdog.sh |
| Máquina caiu | 🔴 | healthchecks.io |

---

## Monitoramento local

```bash
# Status dos serviços
sudo systemctl status claudin-agent
sudo systemctl status claudin-watchdog.timer

# Logs em tempo real
journalctl -u claudin-agent -f

# Último heartbeat
cat claudin/health/.last_heartbeat

# Log de atividade
tail -f claudin/health/activity.log
```

---

## Teste manual

```bash
# Testar sem systemd
bash claudin/scripts/start.sh

# Testar watchdog
bash claudin/health/watchdog.sh

# Testar heartbeat
bash claudin/health/heartbeat.sh
```

---

## Detalhes da estratégia de health check

Veja [docs/architecture.md](docs/architecture.md) para o diagrama completo.

**Resumo:**
- **Máquina caiu** → detectado pelo [healthchecks.io](https://healthchecks.io) (dead man's switch externo)
- **Agente parou** → detectado pelo `claudin-watchdog.timer` (processo local, a cada 5 min)
- **Agente travado em loop** → detectado pelo próprio agente (CLAUDE.md: máx 3 tentativas, máx 10 iterações)
