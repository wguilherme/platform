FROM python:3.11-slim

# Instala esptool no momento do build da imagem
RUN pip install esptool --quiet

# Copia os binários compilados pelo PlatformIO
# (gerados pelo step pio-build do pipeline Tekton)
COPY .pio/build/esp32-usb/bootloader.bin /flash/bootloader.bin
COPY .pio/build/esp32-usb/partitions.bin  /flash/partitions.bin
COPY .pio/build/esp32-usb/firmware.bin    /flash/firmware.bin

# Variáveis configuráveis via env no Job
ENV PORT=/dev/ttyUSB0
ENV BAUD=921600

# Ao rodar o container: flasha e sai
ENTRYPOINT ["sh", "-c", "\
  echo '=== ESP32 Flash ===' && \
  python -m esptool \
    --port $PORT \
    --baud $BAUD \
    --chip esp32 \
    write-flash \
    --flash-mode dio \
    -z \
    0x1000  /flash/bootloader.bin \
    0x8000  /flash/partitions.bin \
    0x10000 /flash/firmware.bin && \
  echo '=== Flash OK ==='\
"]
