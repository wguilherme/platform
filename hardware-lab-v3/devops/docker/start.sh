#!/bin/bash

# Home Assistant + ESPHome Docker Startup Script
# Script para inicializar o ambiente Docker do Home Assistant

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para print colorido
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "=================================================="
echo "🏠 Home Assistant + ESPHome Docker Setup"
echo "Hardware Lab v3 - Controle de Garagem"
echo "=================================================="
echo ""

# Verificar se Docker está instalado
print_status "Verificando instalação do Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker não encontrado. Instale o Docker primeiro."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não encontrado. Instale o Docker Compose primeiro."
    exit 1
fi

print_success "Docker e Docker Compose encontrados"

# Verificar se está no diretório correto
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "Arquivo docker-compose.yml não encontrado."
    print_error "Execute este script do diretório devops/docker/"
    exit 1
fi

# Verificar se o arquivo .env existe
if [[ ! -f ".env" ]]; then
    print_warning "Arquivo .env não encontrado, usando valores padrão"
fi

# Verificar se a pasta homeassistant existe
if [[ ! -d "./homeassistant" ]]; then
    print_error "Pasta homeassistant não encontrada em ./homeassistant"
    print_error "Certifique-se de que a estrutura do projeto está correta"
    exit 1
fi

# Verificar se a pasta esphome existe
if [[ ! -d "../../esphome" ]]; then
    print_error "Pasta esphome não encontrada em ../../esphome"
    print_error "Certifique-se de que a estrutura do projeto está correta"
    exit 1
fi

print_success "Estrutura de arquivos verificada"

# Parar containers existentes se estiverem rodando
print_status "Parando containers existentes..."
docker-compose down 2>/dev/null || true

# Fazer pull das imagens mais recentes
print_status "Baixando imagens mais recentes..."
docker-compose pull

# Iniciar os serviços
print_status "Iniciando serviços Home Assistant + ESPHome..."
docker-compose up -d

# Aguardar os serviços ficarem disponíveis
print_status "Aguardando serviços ficarem disponíveis..."
sleep 15

# Verificar se os containers estão rodando
if docker-compose ps | grep -q "Up"; then
    print_success "Home Assistant e ESPHome iniciados com sucesso!"
    echo ""
    echo "=================================================="
    echo "🎉 Setup Completo!"
    echo "=================================================="
    echo ""
    echo "🏠 Home Assistant:"
    echo "   • Local: http://localhost:8123"
    echo "   • Rede:  http://$(hostname -I | awk '{print $1}'):8123"
    echo ""
    echo "📊 ESPHome Dashboard:"
    echo "   • Local: http://localhost:6052"
    echo "   • Rede:  http://$(hostname -I | awk '{print $1}'):6052"
    echo "   • Usuário: esphome"
    echo "   • Senha:  esphome123"
    echo ""
    echo "📋 Comandos úteis:"
    echo "   • Ver logs HA:     docker-compose logs -f homeassistant"
    echo "   • Ver logs ESPHome: docker-compose logs -f esphome"
    echo "   • Parar serviços:   docker-compose down"
    echo "   • Reiniciar:        docker-compose restart"
    echo ""
    echo "📱 Dispositivo ESP32:"
    echo "   • Nome: garagem-esp32"
    DEVICE_IP=$(ping -c 1 garagem-esp32.local 2>/dev/null | grep -oP '(?<=\()[^)]+' | head -1 || echo 'Não encontrado')
    echo "   • IP:   $DEVICE_IP"
    echo "   • URL:  http://garagem-esp32.local"
    echo ""
    echo "🔧 Próximos passos:"
    echo "   1. Acesse o Home Assistant e complete a configuração inicial"
    echo "   2. Vá em Settings > Devices & Services > Add Integration"
    echo "   3. Procure por 'ESPHome' e adicione o dispositivo 'garagem-esp32.local'"
    echo "   4. Use a senha da API: 'esp32_garagem_api'"
    echo ""
    echo "=================================================="
else
    print_error "Falha ao iniciar os serviços"
    print_status "Verificando logs..."
    docker-compose logs --tail=20
    exit 1
fi