from datetime import datetime
import os

from flask import Flask, jsonify

app = Flask(__name__)
tenant = os.getenv("TENANT_NAME", "unknown-tenant")


@app.get("/")
def index():
    return jsonify(
        {
            "message": "Hello from Flask tenant app",
            "tenant": tenant,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }
    )


@app.get("/healthz")
def health():
    return "ok", 200


@app.get("/readyz")
def ready():
    return "ready", 200
