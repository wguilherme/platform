# Claudin — Arquitetura de Health Check e Monitoramento

## Problema: Como saber se o agente parou?

Existem dois cenários diferentes que precisam de estratégias diferentes:

```
┌──────────────────────────────────────────────────────────────────┐
│                    CENÁRIOS DE FALHA                             │
├──────────────────┬───────────────────────────────────────────────┤
│ Cenário 1        │ Máquina CAIU (RPi desligou, sem energia, etc)  │
│                  │ → Nenhum processo local consegue alertar       │
│                  │ → Precisa de monitoramento EXTERNO             │
├──────────────────┼───────────────────────────────────────────────┤
│ Cenário 2        │ Máquina UP mas agente PAROU/TRAVOU             │
│                  │ → Um processo local pode detectar              │
│                  │ → Watchdog local resolve                       │
└──────────────────┴───────────────────────────────────────────────┘
```

---

## Estratégia: Dead Man's Switch + Watchdog Local

### Dead Man's Switch (para queda da máquina)

O padrão "Dead Man's Switch" funciona ao contrário: em vez de alertar quando algo acontece, você alerta quando algo PARA de acontecer.

```
┌─────────────┐   ping a cada 5min   ┌──────────────────────┐
│   Claudin   │ ──────────────────→  │  healthchecks.io     │
│  (RPi)      │                      │  (serviço externo)   │
└─────────────┘                      └──────────────────────┘
                                              │
                       Se ping parar          │ alerta
                       por >10 min            ↓
                                      ┌───────────────┐
                                      │    Discord    │
                                      │  (seu canal)  │
                                      └───────────────┘
```

**Serviços gratuitos recomendados:**
- [healthchecks.io](https://healthchecks.io) — Melhor opção, free tier generoso
- [BetterUptime](https://betteruptime.com) — Também bom
- [UptimeRobot](https://uptimerobot.com) — Popular

**Como configurar no healthchecks.io:**
1. Crie conta em https://healthchecks.io
2. Crie um "Check" com: Period = 5 min, Grace = 5 min
3. Configure alerta no Discord via webhook
4. Copie a ping URL para o `.env`: `HEALTHCHECK_PING_URL=https://hc-ping.com/UUID`

### Watchdog Local (para agente travado)

```
┌─────────────────────────────────────────────────────────────┐
│                      MÁQUINA (RPi)                          │
│                                                             │
│  ┌─────────────┐  heartbeat    ┌───────────────────────┐   │
│  │   Claudin   │ ────────────→ │  .last_heartbeat file │   │
│  │   (agente)  │               └───────────────────────┘   │
│  └─────────────┘                          ↑                 │
│                                           │ lê              │
│  ┌─────────────────────────────┐          │                 │
│  │  claudin-watchdog.timer     │          │                 │
│  │  (systemd, a cada 5 min)   │──────────┘                 │
│  └─────────────────────────────┘                           │
│                │                                            │
│                │ se parado > 10 min                         │
│                ↓                                            │
│        alerta no Discord                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Fluxo Completo

```
Boot do RPi
    │
    ├─→ claudin-agent.service inicia
    │       │
    │       ├─→ startup-notify.sh → Discord: "🤖 Online"
    │       │
    │       └─→ claude --channels discord ... --dangerously-skip-permissions
    │               │
    │               └─→ Loop de trabalho (CLAUDE.md)
    │                       │
    │                       ├─→ heartbeat.sh a cada tarefa/10min
    │                       │       ├─→ atualiza .last_heartbeat
    │                       │       └─→ ping healthchecks.io
    │                       │
    │                       ├─→ Tarefa concluída → Discord: "✅"
    │                       ├─→ Travado → Discord: "🆘"
    │                       └─→ Sem tarefas → Discord: "💤"
    │
    └─→ claudin-watchdog.timer (a cada 5 min)
            │
            └─→ watchdog.sh
                    ├─→ lê .last_heartbeat
                    ├─→ se parado > 10 min → Discord: "🚨"
                    └─→ cooldown de 30 min (não spamma)
```

---

## Serviços Systemd

| Serviço | Tipo | Função |
|---------|------|--------|
| `claudin-agent.service` | simple, restart=on-failure | Agente principal Claude Code |
| `claudin-watchdog.service` | oneshot | Execução única do watchdog |
| `claudin-watchdog.timer` | timer (5min) | Dispara o watchdog periodicamente |

---

## Alertas no Discord

| Situação | Quem envia | Canal |
|----------|-----------|-------|
| Agente iniciou | `startup-notify.sh` | Webhook |
| Tarefa concluída | Agente (MCP tool) | Webhook |
| Agente travado | Agente (MCP tool) | Webhook |
| Sem tarefas | Agente (MCP tool) | Webhook |
| Agente parou (watchdog) | `watchdog.sh` | Webhook |
| Máquina caiu | `healthchecks.io` | Webhook externo |
