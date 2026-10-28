from app.main import create_app


def client():
    app = create_app()
    app.config.update(TESTING=True)
    return app.test_client()


def test_index_returns_service_metadata():
    response = client().get("/")
    body = response.get_json()

    assert response.status_code == 200
    assert body["service"] == "devops-lab-api"
    assert body["environment"] == "local"


def test_health_returns_ok():
    response = client().get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_ready_returns_ready():
    response = client().get("/ready")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ready"}


def test_unknown_route_returns_404():
    response = client().get("/does-not-exist")

    assert response.status_code == 404
