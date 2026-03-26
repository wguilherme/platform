PORT     ?= /dev/cu.usbserial-0001
BAUD     ?= 115200

COMMON_PORTS := \
	/dev/cu.usbserial-0001 \
	/dev/cu.SLAB_USBtoUART \
	/dev/cu.usbserial-0002 \
	/dev/cu.usbserial \
	/dev/cu.wchusbserial10 \
	/dev/cu.wchusbserial \
	/dev/cu.usbmodem

.PHONY: detect flash monitor

detect:
	@echo "=== Porta configurada no flash.sh ==="
	@if [ -e "$(PORT)" ]; then \
		echo "[OK] $(PORT) encontrada"; \
	else \
		echo "[--] $(PORT) nao encontrada"; \
	fi
	@echo ""
	@echo "=== Portas comuns ==="
	@found=0; \
	for p in $(COMMON_PORTS); do \
		if [ -e "$$p" ]; then \
			echo "[OK] $$p"; \
			found=1; \
		else \
			echo "[--] $$p"; \
		fi; \
	done; \
	echo ""; \
	echo "=== Todos os dispositivos USB/serial detectados ==="; \
	detected=$$(ls /dev/cu.* 2>/dev/null | grep -Ev "Bluetooth|debug-console|wlan-debug|BeatsFitPro"); \
	if [ -n "$$detected" ]; then \
		echo "$$detected"; \
	else \
		echo "Nenhum dispositivo USB serial encontrado."; \
		echo "Verifique o cabo (precisa ter fios de dados, nao apenas carga)."; \
	fi

flash:
	@./flash.sh

monitor:
	screen $(PORT) $(BAUD)
