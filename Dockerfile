# Stage 1: install dependencies into an isolated prefix.
FROM python:3.12-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# Stage 2: minimal runtime image that runs as a non-root user.
FROM python:3.12-slim AS runtime

ARG APP_VERSION=dev

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    APP_ENV=production \
    APP_VERSION=${APP_VERSION}

RUN groupadd --gid 1001 app \
    && useradd --uid 1001 --gid app --create-home app

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app ./app

USER app
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--access-logfile", "-", "app.main:app"]
