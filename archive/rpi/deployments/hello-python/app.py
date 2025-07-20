from flask import Flask, jsonify # type: ignore

app = Flask(__name__)

@app.route('/', methods=['GET'])
def hello():
    return jsonify("Hello World! Python is running in a Kubernetes Pod on Raspberry Pi!")

@app.route('/liveness', methods=['GET'])
def liveness():
    return jsonify(status="up")

@app.route('/readiness', methods=['GET'])
def readiness():
    return jsonify(status="ready"), 200

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=80)