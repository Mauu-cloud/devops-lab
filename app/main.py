import os

from flask import Flask, jsonify

app = Flask(__name__)
VERSION = os.getenv("APP_VERSION", "dev")


@app.get("/")
def index():
    return jsonify(message="Hola desde devops-lab", version=VERSION)


@app.get("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
