#!/usr/bin/env bash
# install.sh — Instala e configura o Claudin no servidor
#
# Execute com: bash claudin/scripts/install.sh
# Requer: Raspberry Pi OS / Debian, usuário 'pi', sudo

set -euo pipefail

PROJECT_DIR="/home/pi/project"
CLAUDIN_DIR="${PROJECT_DIR}/claudin"

echo "=================================================="
echo "  Claudin — Instalação"
echo "=================================================="

# ── 1. Verificações ───────────────────────────────────────────
echo ""
echo "→ Verificando dependências..."

# Verifica se claude está instalado e logado
if ! command -v claude &>/dev/null; then
  echo ""
  echo "❌ claude não encontrado."
  echo "   Instale o Claude Code CLI:"
  echo "   npm install -g @anthropic-ai/claude-code"
  echo ""
  echo "   IMPORTANTE: Claude Code Channels só funciona com login via CLI"
  echo "   (não funciona com ANTHROPIC_API_KEY)"
  echo "   Após instalar, execute: claude login"
  exit 1
fi

# Verifica se está logado (Claude Code Channels requer login, não API key)
if ! claude --version &>/dev/null; then
  echo "❌ Claude Code não está funcionando corretamente"
  exit 1
fi

echo "   ✓ claude instalado"

# Verifica bun
if ! command -v bun &>/dev/null; then
  echo "   Instalando Bun..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="${HOME}/.bun/bin:${PATH}"
fi
echo "   ✓ bun disponível"

# ── 2. Arquivo .env ───────────────────────────────────────────
echo ""
echo "→ Configurando variáveis de ambiente..."

if [ ! -f "${CLAUDIN_DIR}/.env" ]; then
  cp "${CLAUDIN_DIR}/.env.example" "${CLAUDIN_DIR}/.env"
  echo ""
  echo "⚠️  Arquivo .env criado em ${CLAUDIN_DIR}/.env"
  echo "   Edite-o antes de continuar:"
  echo "   nano ${CLAUDIN_DIR}/.env"
  echo ""
  echo "   Valores necessários:"
  echo "   - DISCORD_BOT_TOKEN"
  echo "   - DISCORD_WEBHOOK_URL"
  echo "   - HEALTHCHECK_PING_URL (opcional mas recomendado)"
  echo ""
  read -rp "Pressione Enter após editar o .env para continuar..."
fi

source "${CLAUDIN_DIR}/.env"

# ── 3. Dependências do MCP Server ─────────────────────────────
echo ""
echo "→ Instalando dependências do MCP server..."
cd "${CLAUDIN_DIR}/channels"
bun add @modelcontextprotocol/sdk
echo "   ✓ dependências instaladas"

# ── 4. Permissões dos scripts ─────────────────────────────────
echo ""
echo "→ Configurando permissões dos scripts..."
chmod +x "${CLAUDIN_DIR}/health/"*.sh
chmod +x "${CLAUDIN_DIR}/hooks/"*.sh
chmod +x "${CLAUDIN_DIR}/scripts/"*.sh
echo "   ✓ permissões configuradas"

# ── 5. Instalar plugin Discord no Claude Code ─────────────────
echo ""
echo "→ Instalando plugin Discord no Claude Code..."
echo "   Execute manualmente em uma sessão Claude Code:"
echo "   /plugin install discord@claude-plugins-official"
echo "   /discord:configure ${DISCORD_BOT_TOKEN:-SEU_TOKEN_AQUI}"
echo ""

# ── 6. Copiar settings.json ───────────────────────────────────
echo ""
echo "→ Configurando settings do Claude Code..."
CLAUDE_SETTINGS_DIR="${HOME}/.claude"
mkdir -p "${CLAUDE_SETTINGS_DIR}"

if [ ! -f "${CLAUDE_SETTINGS_DIR}/settings.json" ]; then
  cp "${CLAUDIN_DIR}/settings/settings.json" "${CLAUDE_SETTINGS_DIR}/settings.json"
  echo "   ✓ settings.json copiado para ${CLAUDE_SETTINGS_DIR}/"
else
  echo "   ⚠️  settings.json já existe em ${CLAUDE_SETTINGS_DIR}/"
  echo "   Revise manualmente: ${CLAUDIN_DIR}/settings/settings.json"
fi

# ── 7. Instalar serviços systemd ──────────────────────────────
echo ""
echo "→ Instalando serviços systemd..."

# Ajusta paths no service file para o servidor atual
sed "s|/home/pi/project|${PROJECT_DIR}|g" \
  "${CLAUDIN_DIR}/systemd/claudin-agent.service" > /tmp/claudin-agent.service

sed "s|/home/pi/project|${PROJECT_DIR}|g" \
  "${CLAUDIN_DIR}/systemd/claudin-watchdog.service" > /tmp/claudin-watchdog.service

sudo cp /tmp/claudin-agent.service /etc/systemd/system/claudin-agent.service
sudo cp "${CLAUDIN_DIR}/systemd/claudin-watchdog.service" /etc/systemd/system/claudin-watchdog.service
sudo cp "${CLAUDIN_DIR}/systemd/claudin-watchdog.timer" /etc/systemd/system/claudin-watchdog.timer

sudo systemctl daemon-reload
sudo systemctl enable claudin-watchdog.timer

echo "   ✓ serviços instalados"

# ── 8. Configurar Git ─────────────────────────────────────────
echo ""
echo "→ Configurando Git..."

source "${CLAUDIN_DIR}/.env"

if [ -n "${GIT_USER_NAME:-}" ]; then
  git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi
if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "$SSH_KEY_PATH" ]; then
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY_PATH"
  echo "   ✓ chave SSH carregada: ${SSH_KEY_PATH}"
fi

echo "   ✓ Git configurado"

# ── 9. Criar diretório de health ──────────────────────────────
mkdir -p "${CLAUDIN_DIR}/health"
touch "${CLAUDIN_DIR}/health/activity.log"
touch "${CLAUDIN_DIR}/health/heartbeat.log"

# ── Resumo ────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo "  ✅ Instalação concluída!"
echo "=================================================="
echo ""
echo "Próximos passos:"
echo ""
echo "  1. Faça login no Claude Code (OBRIGATÓRIO para Channels):"
echo "     claude login"
echo ""
echo "  2. Inicie uma sessão Claude Code e instale o plugin:"
echo "     /plugin install discord@claude-plugins-official"
echo "     /discord:configure \${DISCORD_BOT_TOKEN}"
echo ""
echo "  3. Configure o Discord Bot no Developer Portal:"
echo "     - Habilite Message Content Intent"
echo "     - Convide o bot ao servidor com permissões de leitura/escrita"
echo ""
echo "  4. Configure healthchecks.io (recomendado):"
echo "     - Crie conta em https://healthchecks.io"
echo "     - Crie um check com período de 10 min e grace de 5 min"
echo "     - Adicione a URL no .env: HEALTHCHECK_PING_URL"
echo ""
echo "  5. Inicie o agente:"
echo "     sudo systemctl start claudin-agent"
echo "     sudo systemctl start claudin-watchdog.timer"
echo ""
echo "  6. Monitore os logs:"
echo "     journalctl -u claudin-agent -f"
echo ""
