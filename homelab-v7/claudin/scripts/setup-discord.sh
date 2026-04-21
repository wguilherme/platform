#!/usr/bin/env bash
# setup-discord.sh — Configura o Discord plugin no Claude Code
#
# Idempotente: detecta o que já foi feito e pula essas etapas.
#
# O plugin discord é um "external_plugin" bundled no marketplace —
# não pode ser instalado via "claude plugin install" (source relativo).
# A solução é registrá-lo manualmente no cache e installed_plugins.json.

set -euo pipefail

CLAUDIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Paths do Claude Code
INSTALLED_PLUGINS="${HOME}/.claude/plugins/installed_plugins.json"
PLUGIN_CACHE="${HOME}/.claude/plugins/cache/claude-plugins-official/discord"
DISCORD_EXTERNAL="${HOME}/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/discord"
DISCORD_ENV_DIR="${HOME}/.claude/channels/discord"
DISCORD_ENV="${DISCORD_ENV_DIR}/.env"
DISCORD_ACCESS="${DISCORD_ENV_DIR}/access.json"
PLUGIN_KEY="discord@claude-plugins-official"

# ── Cores ─────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}[$(date '+%H:%M:%S')]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
skip() { echo -e "${YELLOW}  ↷${NC} $1 (já feito)"; }
fail() { echo -e "${RED}  ✗${NC} $1"; exit 1; }
info() { echo -e "  $1"; }

# ── Carrega .env do projeto ───────────────────────────────────
[ -f "${CLAUDIN_DIR}/.env" ] && { set -a; source "${CLAUDIN_DIR}/.env"; set +a; }
DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"

echo ""
echo "=================================================="
echo "  Claudin — Setup Discord Plugin"
echo "=================================================="

# ══ ETAPA 1: Registrar plugin no cache ═══════════════════════
step "Etapa 1/3 — Instalar plugin Discord"

# Detecta se plugin já está registrado no installed_plugins.json
PLUGIN_INSTALLED=false
if [ -f "$INSTALLED_PLUGINS" ]; then
  python3 -c "
import json, sys
d = json.load(open('$INSTALLED_PLUGINS'))
sys.exit(0 if '$PLUGIN_KEY' in d.get('plugins', {}) else 1)
" 2>/dev/null && PLUGIN_INSTALLED=true || true
fi

if $PLUGIN_INSTALLED; then
  skip "Plugin já registrado"
else
  # Verifica que o plugin existe no marketplace
  if [ ! -d "$DISCORD_EXTERNAL" ]; then
    info "Plugin não encontrado localmente. Atualizando marketplace..."
    claude plugin marketplace update 2>/dev/null || true
  fi

  [ -d "$DISCORD_EXTERNAL" ] || fail "Plugin discord não encontrado em ${DISCORD_EXTERNAL}"

  # Lê versão do plugin
  PLUGIN_VERSION=$(python3 -c "
import json
d = json.load(open('${DISCORD_EXTERNAL}/.claude-plugin/plugin.json'))
print(d.get('version', '0.0.4'))
" 2>/dev/null || echo "0.0.4")

  # Copia para o cache (estrutura esperada pelo Claude Code)
  INSTALL_PATH="${PLUGIN_CACHE}/${PLUGIN_VERSION}"
  mkdir -p "$INSTALL_PATH"
  cp -r "${DISCORD_EXTERNAL}/." "$INSTALL_PATH/"
  info "Plugin copiado para cache: ${INSTALL_PATH}"

  # Instala dependências do plugin
  if [ -f "${INSTALL_PATH}/package.json" ]; then
    info "Instalando dependências do plugin..."
    (cd "$INSTALL_PATH" && bun install --silent 2>/dev/null) || true
  fi

  # Registra no installed_plugins.json
  NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
  python3 - <<PYEOF
import json, os
path = '$INSTALLED_PLUGINS'
if os.path.exists(path):
    d = json.load(open(path))
else:
    d = {"version": 2, "plugins": {}}

d['plugins']['$PLUGIN_KEY'] = [{
    "scope": "user",
    "installPath": "$INSTALL_PATH",
    "version": "$PLUGIN_VERSION",
    "installedAt": "$NOW",
    "lastUpdated": "$NOW"
}]

json.dump(d, open(path, 'w'), indent=4)
print("Registrado em installed_plugins.json")
PYEOF

  ok "Plugin registrado (v${PLUGIN_VERSION})"
fi

# ══ ETAPA 2: Configurar bot token ═════════════════════════════
step "Etapa 2/3 — Configurar bot token"

TOKEN_CONFIGURED=false
if [ -f "$DISCORD_ENV" ]; then
  SAVED_TOKEN=$(grep "^DISCORD_BOT_TOKEN" "$DISCORD_ENV" 2>/dev/null | cut -d= -f2 || echo "")
  [ -n "$SAVED_TOKEN" ] && TOKEN_CONFIGURED=true
fi

if $TOKEN_CONFIGURED; then
  skip "Token já configurado em ${DISCORD_ENV}"
else
  # Pede token se não estiver no .env
  if [ -z "$DISCORD_BOT_TOKEN" ]; then
    echo ""
    info "${YELLOW}DISCORD_BOT_TOKEN não encontrado no .env${NC}"
    read -rp "  Cole o Bot Token do Discord: " DISCORD_BOT_TOKEN
    [ -z "$DISCORD_BOT_TOKEN" ] && fail "Token não fornecido"
  fi

  mkdir -p "$DISCORD_ENV_DIR"
  echo "DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}" > "$DISCORD_ENV"
  ok "Token salvo em ${DISCORD_ENV}"
fi

# ══ ETAPA 3: Parear conta Discord ═════════════════════════════
step "Etapa 3/4 — Parear conta Discord"

PAIRED=false
if [ -f "$DISCORD_ACCESS" ]; then
  python3 -c "
import json, sys
d = json.load(open('$DISCORD_ACCESS'))
sys.exit(0 if d.get('policy') == 'allowlist' and d.get('allowlist') else 1)
" 2>/dev/null && PAIRED=true || true
fi

if $PAIRED; then
  skip "Conta já pareada"
else
  PENDING_CODE="${CLAUDIN_DIR}/.pending_pair_code"

  echo ""
  echo -e "  ${YELLOW}Ação manual necessária — siga os passos:${NC}"
  echo ""
  info "1. Inicie o agente com channels ativo (em outro terminal):"
  info "   ${CYAN}cd ${CLAUDIN_DIR} && make start${NC}"
  echo ""
  info "2. No Discord, mande um DM para o seu bot"
  info "   O bot responde com um código de pareamento"
  echo ""
  info "3. De volta ao terminal Claude Code, rode:"
  info "   ${CYAN}/discord:access pair CODIGO${NC}"
  info "   ${CYAN}/discord:access policy allowlist${NC}"
  echo ""

  read -rp "  Pressione Enter para continuar ou 's' para pular: " SKIP_PAIR
  if [[ "$SKIP_PAIR" == "s" || "$SKIP_PAIR" == "S" ]]; then
    echo -e "  ${YELLOW}↷${NC} Pareamento pulado — conclua manualmente depois"
  else
    read -rp "  Tem o código de pareamento? Cole aqui (ou Enter para pular): " PAIR_CODE
    if [ -n "$PAIR_CODE" ]; then
      echo "$PAIR_CODE" > "$PENDING_CODE"
      info "Código salvo. Rode dentro da sessão Claude Code com --channels:"
      info "  /discord:access pair ${PAIR_CODE}"
      info "  /discord:access policy allowlist"
    fi
  fi
fi

# ══ ETAPA 4: Habilitar canal do servidor ══════════════════════
step "Etapa 4/4 — Habilitar canal do servidor Discord"

DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID:-}"

# Tenta puxar do .env se não estiver na env
if [ -z "$DISCORD_CHANNEL_ID" ] && [ -f "${CLAUDIN_DIR}/.env" ]; then
  DISCORD_CHANNEL_ID=$(grep "^DISCORD_CHANNEL_ID" "${CLAUDIN_DIR}/.env" | cut -d= -f2 || echo "")
fi

CHANNEL_CONFIGURED=false
if [ -f "$DISCORD_ACCESS" ] && [ -n "$DISCORD_CHANNEL_ID" ]; then
  python3 -c "
import json, sys
d = json.load(open('$DISCORD_ACCESS'))
sys.exit(0 if '$DISCORD_CHANNEL_ID' in d.get('groups', {}) else 1)
" 2>/dev/null && CHANNEL_CONFIGURED=true || true
fi

if $CHANNEL_CONFIGURED; then
  skip "Canal ${DISCORD_CHANNEL_ID} já habilitado"
else
  # Pede o channel ID se não encontrado
  if [ -z "$DISCORD_CHANNEL_ID" ]; then
    echo ""
    info "${YELLOW}DISCORD_CHANNEL_ID não encontrado no .env${NC}"
    info "Para obter: Discord → Settings → Advanced → Developer Mode"
    info "Depois clique com botão direito no canal → Copy Channel ID"
    echo ""
    read -rp "  Cole o Channel ID (ou Enter para pular): " DISCORD_CHANNEL_ID
  fi

  if [ -z "$DISCORD_CHANNEL_ID" ]; then
    echo -e "  ${YELLOW}↷${NC} Canal pulado — o bot responderá apenas via DM"
  else
    # Escreve diretamente no access.json (sem precisar de slash command)
    mkdir -p "$DISCORD_ENV_DIR"
    python3 - <<PYEOF
import json, os

path = '$DISCORD_ACCESS'
if os.path.exists(path):
    d = json.load(open(path))
else:
    d = {}

if 'groups' not in d:
    d['groups'] = {}

d['groups']['$DISCORD_CHANNEL_ID'] = {
    'requireMention': False,
    'allowFrom': []
}

json.dump(d, open(path, 'w'), indent=2)
print("Canal registrado em access.json")
PYEOF

    ok "Canal ${DISCORD_CHANNEL_ID} habilitado (--no-mention)"
    info "O bot responderá a qualquer mensagem neste canal"

    # Salva no .env se ainda não estiver lá
    if ! grep -q "^DISCORD_CHANNEL_ID" "${CLAUDIN_DIR}/.env" 2>/dev/null; then
      echo "DISCORD_CHANNEL_ID=${DISCORD_CHANNEL_ID}" >> "${CLAUDIN_DIR}/.env"
      info "DISCORD_CHANNEL_ID salvo no .env"
    fi
  fi
fi

# ── Resumo ────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo -e "${GREEN}  Setup concluído!${NC}"
echo "=================================================="
echo ""
info "Próximo passo — iniciar o agente:"
echo ""
info "  ${CYAN}make start${NC}    → local (Mac)"
info "  ${CYAN}make start-pi${NC} → produção (Raspberry Pi)"
echo ""
