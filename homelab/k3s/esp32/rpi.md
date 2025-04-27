### requirements

sudo apt install -y linux-modules-extra-raspi
sudo apt install -y usbutils

sudo apt install -y minicom
sudo minicom -D /dev/ttyACM0


https://www.silabs.com/developer-tools/usb-to-uart-bridge-vcp-drivers?tab=downloads

brew install cmake ninja dfu-util
brew install ccache




sudo apt update
sudo apt install -y python3-pip
sudo apt install python3.10-venv
sudo apt install -y python3-pip python3-venv
python3 -m pip install --upgrade pip
sudo apt install -y git
sudo apt install -y usbutils
sudo apt install -y minicom

mkdir -p ~/esp
cd ~/esp
git clone --recursive https://github.com/espressif/esp-idf.git

cd ~/esp/esp-idf
./install.sh all


export ESP_IDF_EXPORT_DEBUG=1
. ./export.sh


lsusb
dmesg | grep tty


sudo usermod -a -G dialout $USER
sudo reboot

sudo apt install -y usb-serial-ch341-dkms

sudo apt install -y linux-modules-extra-raspi
sudo apt install -y usbutils
sudo apt install -y build-essential
sudo apt install -y dkms
sudo apt install -y linux-headers-$(uname -r)

find /lib/modules/$(uname -r) -type f -name '*ch341*'

sudo apt install -y minicom

sudo modprobe usbserial
sudo modprobe ch341
sudo modprobe cp210x




wguilherme@rpi1:~$ lsmod | grep -E "usbserial|ch341|cp210x"
cp210x                 36864  0
ch341                  24576  0
usbserial              61440  2 cp210x,ch341



ESP8266: geralmente usa CH340/CH341 (ch34)
ESP32: geralmente usa CP210x (cp210) ou, em alguns casos, FTDI (ftdi)


ps: foi necessário dar load module

esp32:
lsmod | grep -E "usbserial|ch341|cp210x"


## Troubleshooting USB Serial (ESP32/ESP8266 no Raspberry Pi)

### 1. Verificar módulos/drivers carregados

Execute os comandos abaixo para checar se os principais módulos estão instalados e carregados:

```sh
lsmod | grep ch34    # Para CH340/CH341
lsmod | grep cp210   # Para CP210x
lsmod | grep ftdi    # Para FTDI
```

Se não aparecer nada, tente carregar manualmente:

```sh
sudo modprobe ch341
sudo modprobe cp210x
sudo modprobe ftdi_sio
```

Para garantir que os módulos estão instalados:

```sh
sudo apt install dkms
```

### 2. Verificar se o dispositivo foi reconhecido

Após conectar o ESP, rode:

```sh
dmesg | tail -30
```

```sh
lsusb
```

Procure por linhas relacionadas ao chip USB-Serial (ex: "QinHeng Electronics CH340", "Silicon Labs CP210x", "FTDI", etc).

### 3. Verificação específica

#### Para ESP32

- Normalmente aparece como `/dev/ttyUSB0` ou `/dev/ttyACM0`.
- No `lsusb`, procure por "Silicon Labs" (CP210x) ou "FTDI".

#### Para ESP8266

- Normalmente aparece como `/dev/ttyUSB0`.
- No `lsusb`, procure por "QinHeng Electronics" (CH340/CH341).

#### Comando para listar dispositivos seriais:

```sh
ls /dev/ttyUSB* /dev/ttyACM*
```

#### Permissões

Adicione seu usuário ao grupo `dialout` se necessário:

```sh
sudo usermod -aG dialout $USER
```

### Teste de Comunicação

1. **Verificar porta serial**
```bash
ls -l /dev/ttyUSB*
```

2. **Testar comunicação**
```bash
# Configure minicom
sudo minicom -D /dev/ttyUSB0 -b 115200

# Ou use screen
screen /dev/ttyUSB0 115200
```

3. **Verificar permissões**
```bash
# Deve mostrar que você está no grupo dialout
groups
```

4. **Teste com ESP-IDF**
```bash
cd ~/esp/hello_esp32
idf.py -p /dev/ttyUSB0 flash monitor
