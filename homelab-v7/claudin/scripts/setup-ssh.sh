#!/usr/bin/env bash
# setup-ssh.sh — Configura chave SSH para o agente
#
# Gera ou valida a chave SSH usada pelo agente para push no Git.
# Execute uma vez durante a instalação.

set -euo pipefail

CLAUDIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

source "${CLAUDIN_DIR}/.env" 2>/dev/null || true

SSH_KEY_PATH="${SSH_KEY_PATH:-/home/pi/.ssh/claudin_ed25519}"
SSH_DIR="$(dirname "$SSH_KEY_PATH")"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-claudin@orion.dev}"

echo "=================================================="
echo "  Claudin — Setup de Chave SSH"
echo "=================================================="
echo ""

# ── 1. Cria diretório .ssh se não existir ─────────────────────
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ── 2. Gera chave se não existir ──────────────────────────────
if [ -f "$SSH_KEY_PATH" ]; then
  echo "✓ Chave SSH já existe: ${SSH_KEY_PATH}"
else
  echo "→ Gerando nova chave SSH..."
  ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
  echo "✓ Chave gerada: ${SSH_KEY_PATH}"
fi

# ── 3. Adiciona GitHub ao known_hosts ─────────────────────────
KNOWN_HOSTS="${SSH_DIR}/known_hosts"
if ! grep -q "github.com" "$KNOWN_HOSTS" 2>/dev/null; then
  echo "→ Adicionando GitHub ao known_hosts..."
  ssh-keyscan -t ed25519 github.com >> "$KNOWN_HOSTS" 2>/dev/null
  echo "✓ github.com adicionado ao known_hosts"
else
  echo "✓ github.com já está no known_hosts"
fi

# ── 4. Configura ssh-agent no .bashrc ─────────────────────────
BASHRC="${HOME}/.bashrc"
SSH_AGENT_BLOCK="# Claudin SSH Agent
if [ -z \"\$SSH_AUTH_SOCK\" ]; then
  eval \"\$(ssh-agent -s)\" > /dev/null
  ssh-add ${SSH_KEY_PATH} 2>/dev/null
fi"

if ! grep -q "Claudin SSH Agent" "$BASHRC" 2>/dev/null; then
  echo "" >> "$BASHRC"
  echo "$SSH_AGENT_BLOCK" >> "$BASHRC"
  echo "✓ ssh-agent configurado no .bashrc"
fi

# ── 5. Cria config SSH para GitHub ───────────────────────────
SSH_CONFIG="${SSH_DIR}/config"
GITHUB_CONFIG="Host github.com
  HostName github.com
  User git
  IdentityFile ${SSH_KEY_PATH}
  IdentitiesOnly yes"

if ! grep -q "IdentityFile ${SSH_KEY_PATH}" "$SSH_CONFIG" 2>/dev/null; then
  echo "" >> "$SSH_CONFIG"
  echo "$GITHUB_CONFIG" >> "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  echo "✓ Configuração SSH criada para github.com"
fi

# ── 6. Exibe chave pública ────────────────────────────────────
echo ""
echo "=================================================="
echo "  Chave pública — adicione ao GitHub"
echo "=================================================="
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""
echo "→ Adicione esta chave em:"
echo "   https://github.com/settings/ssh/new"
echo "   Título sugerido: claudin-$(hostname)"
echo ""

# ── 7. Testa conexão (opcional) ───────────────────────────────
echo "→ Testando conexão com GitHub..."
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add "$SSH_KEY_PATH" > /dev/null 2>&1

if ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated"; then
  echo "✓ Conexão com GitHub OK!"
else
  echo "⚠️  Conexão não confirmada ainda."
  echo "   Adicione a chave pública ao GitHub e teste com: ssh -T git@github.com"
fi

echo ""
echo "✅ Setup SSH concluído"
