import os

from flask import Flask, jsonify


def create_app():
    app = Flask(__name__)

    @app.get("/")
    def index():
        return jsonify(
            service="devops-lab-api",
            message="Hello from DevOps Lab!",
            version=os.getenv("APP_VERSION", "dev"),
            environment=os.getenv("APP_ENV", "local"),
        )

    @app.get("/health")
    def health():
        return jsonify(status="ok"), 200

    @app.get("/ready")
    def ready():
        return jsonify(status="ready"), 200

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
