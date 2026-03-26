from flask import Flask, request
import RPi.GPIO as GPIO
import unicodedata
import time

RELAY_PIN     = 17
PULSE_SECONDS = 1.5
APPROVED      = ["5522998614590", "22997710206"]  # adicione os números aprovados aqui (sem + e sem espaços)
KEYWORDS      = ["portao"]

GPIO.setmode(GPIO.BCM)
GPIO.setup(RELAY_PIN, GPIO.OUT, initial=GPIO.HIGH)

app = Flask(__name__)

def trigger():
    GPIO.output(RELAY_PIN, GPIO.LOW)
    time.sleep(PULSE_SECONDS)
    GPIO.output(RELAY_PIN, GPIO.HIGH)

@app.route("/pulse", methods=["POST"])
def pulse():
    trigger()
    return "ok"

@app.route("/webhook", methods=["POST"])
def webhook():
    data    = request.json or {}
    payload = data.get("payload", {})
    sender   = payload.get("from", "")
    from_me  = payload.get("fromMe", False)
    raw      = payload.get("body", "")
    message  = unicodedata.normalize("NFD", raw.lower())
    message  = "".join(c for c in message if unicodedata.category(c) != "Mn")

    print(f"[webhook] sender={sender!r} fromMe={from_me} message={message!r}", flush=True)

    if message.strip() in KEYWORDS:
        trigger()

    return "ok"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
