# Lesson 1: Containers with Docker

## Learning goals

By the end of this lesson you can:

- Explain the difference between an image and a container.
- Build, run, inspect, and stop a container.
- Read a multi-stage Dockerfile and explain why it runs as a non-root user.
- Use Docker Compose to run the service with one command.

## Why containers

A container packages the application and its runtime dependencies into a single
artifact. The same image runs on a laptop, in CI, and in Kubernetes. That
consistency is the foundation for everything else in this project.

## Image vs container

- An **image** is an immutable, layered filesystem plus metadata (command,
  environment, user).
- A **container** is a running process with its own filesystem view, network,
  and resource limits, created from an image.

One image can create many containers.

## Walk through the Dockerfile

Open [`Dockerfile`](../Dockerfile).

1. **Builder stage**: installs Python dependencies into `/install` using
   `pip --prefix`. Build tools never reach the runtime image.
2. **Runtime stage**: starts from a clean `python:3.12-slim`, copies only the
   installed packages and the `app/` directory.
3. **Non-root user**: `useradd` creates UID 1001 and `USER app` drops root.
4. **Environment defaults**: `APP_ENV`, `APP_VERSION`, and `PORT` are set.
5. **HEALTHCHECK**: Docker can report whether the container is healthy.
6. **CMD**: Gunicorn serves the Flask app in production mode.

Why multi-stage? Smaller images, fewer vulnerabilities, and no compilers in
production.

## Core commands

```powershell
# Build an image with a tag
docker build -t devops-lab-api:local .

# List images and see the size
docker images devops-lab-api

# Run in the background, map host port 8000 to container 8000
docker run -d --name devops-lab -p 8000:8000 devops-lab-api:local

# Check health and logs
docker ps
docker logs devops-lab
docker inspect --format "{{.State.Health.Status}}" devops-lab

# Hit the endpoints
curl http://localhost:8000/health
curl http://localhost:8000/

# Open a shell in a new container from the same image
docker run --rm -it devops-lab-api:local bash

# Stop and remove
docker stop devops-lab
docker rm devops-lab
```

## Docker Compose

[`docker-compose.yml`](../docker-compose.yml) builds the image, maps the port,
passes environment variables, and defines a health check.

```powershell
docker compose up --build
docker compose ps
docker compose logs -f
docker compose down
```

## Exercises

### Exercise 1.1: First run

Build and run the image. Call `/health` and `/`. Capture the returned version
and environment. Then rebuild with a different `APP_VERSION` build argument:

```powershell
docker build --build-arg APP_VERSION=1.2.3 -t devops-lab-api:1.2.3 .
docker run --rm -p 8001:8000 devops-lab-api:1.2.3
```

Verify that `/` reports `1.2.3`.

### Exercise 1.2: Image size

Record the image size. Then remove the multi-stage split and install
dependencies directly in the runtime image (keep a copy of the original first).
Compare sizes and explain the difference.

### Exercise 1.3: Non-root proof

Run these commands and record the output:

```powershell
docker run --rm devops-lab-api:local id
docker run --rm --user root devops-lab-api:local id
```

Why is running as root risky in production?

### Exercise 1.4: Deliberate failure

Start a container, then use `docker exec` to inspect it while it is running.
Stop the process inside the container and observe the restart behavior with and
without Compose's `restart: unless-stopped`.

### Exercise 1.5: Layer cache

Change only a line inside `app/main.py` and rebuild. Notice that dependency
installation is cached. Now change `requirements.txt` and rebuild. Explain the
difference using the concept of layer invalidation.

## Checkpoint

You are done when you can:

- Build and run the image without looking at this file.
- Explain why the final image has no compilers.
- Show that the container runs as UID 1001.
- Explain how the health check is used by Docker and, later, Kubernetes.
