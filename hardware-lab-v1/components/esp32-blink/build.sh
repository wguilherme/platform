#!/bin/bash

# Verifica se o código fonte foi montado
if [ ! -d "/build/main" ]; then
    echo "Erro: Diretório /build/main não encontrado"
    echo "Monte o código fonte em /build"
    exit 1
fi

# Exporta o ambiente do ESP-IDF
. /esp/esp-idf/export.sh

# Configura o target
idf.py set-target esp32

# Faz o build
echo "Iniciando build..."
idf.py build

# Verifica se o build foi bem sucedido
if [ $? -eq 0 ]; then
    echo "Build concluído com sucesso!"
    echo "Binários gerados em /build/build"
    
    # Lista os binários gerados
    ls -l /build/build/*.bin
    
    # Se estiver em um ambiente CI, você pode fazer upload dos binários aqui
    # Por exemplo:
    # if [ -n "$CI" ]; then
    #     gh release create v1.0.0 /build/build/*.bin
    # fi
else
    echo "Erro durante o build"
    exit 1
fi 