python3 -c "
import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BCM)
GPIO.setup(17, GPIO.OUT, initial=GPIO.HIGH)
GPIO.output(17, GPIO.LOW)
time.sleep(1.5)
GPIO.output(17, GPIO.HIGH)
GPIO.cleanup()
"