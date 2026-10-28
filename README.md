# DevOps Lab

A small, production-shaped Flask API used as a sandbox for learning and teaching
DevOps. The application is intentionally simple so the DevOps concepts stay in
focus.

## What you will learn

- Container fundamentals: images, layers, multi-stage builds, non-root users
- CI with GitHub Actions: lint, test, build, publish an image
- CD: deploy a specific immutable image tag to Kubernetes
- Kubernetes: Deployments, Services, probes, resources, rollouts
- Infrastructure as Code with Terraform: ECR and lifecycle policies
- Operational habits: health checks, supply-chain basics, cleanup
- Teaching: a structured curriculum, exercises, and a demo-day rubric

## Architecture

```text
 Developer
    |
    v
 GitHub repo ---> CI (lint, test, build) ---> GHCR image (tagged by SHA)
                                                     |
                                                     | CD workflow (manual)
                                                     v
                                              Kubernetes cluster
                                                     |
                                                     v
                                                   Users

 Terraform ---> AWS ECR (alternative registry + IaC lesson)
```

## Tech stack

| Layer          | Tool                                      |
| -------------- | ----------------------------------------- |
| Application    | Python 3.12, Flask, Gunicorn              |
| Tests          | Pytest                                    |
| Containers     | Docker, Docker Compose                    |
| CI/CD          | GitHub Actions, GitHub Container Registry  |
| Orchestration  | Kubernetes (Kustomize)                    |
| Infrastructure | Terraform, AWS ECR                        |

## Repository layout

```text
devops-lab/
|-- app/                     Flask application
|-- tests/                   Pytest suite
|-- Dockerfile               Multi-stage, non-root image
|-- docker-compose.yml       Local container workflow
|-- .github/workflows/       CI and CD pipelines
|-- k8s/                     Kubernetes base manifests
|-- k8s/optional/            Ingress and HPA exercises
|-- terraform/               AWS ECR module
|-- docs/                    Lessons and teaching guide
|-- Makefile                 Shortcuts for common tasks
```

## Prerequisites

- Python 3.12+
- Docker
- Optional: a local Kubernetes cluster (Docker Desktop, minikube, or kind)
- Optional: Terraform 1.6+ and AWS credentials for the IaC lesson

## Quick start

### 1. Run locally

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
pytest -q
python -m app.main
```

Open <http://localhost:8000>. The local server uses Flask's development server;
the container uses Gunicorn.

### 2. Build the container

```powershell
docker build -t devops-lab-api:local .
docker run --rm -p 8000:8000 devops-lab-api:local
```

### 3. Run the full local stack

```powershell
docker compose up --build
```

### 4. Stop and clean up

```powershell
docker compose down
```

## CI/CD

CI runs on every push to `main` and every pull request:

1. Lint with Flake8 and run Pytest.
2. Build the Docker image.
3. Push the image to GHCR, tagged with the commit SHA, on non-PR events.

The deploy workflow is manual (`workflow_dispatch`) so learners control when a
release happens. To enable it:

1. Create a Kubernetes Secret named `KUBE_CONFIG` containing a base64-encoded
   kubeconfig:
   `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\.kube\config"))`
2. Add it as a repository or environment secret in GitHub.
3. Make sure `k8s/deployment.yaml` points at your image, or let the workflow set
   it with `kubectl set image`.
4. Run **CD -> Run workflow** and provide the image tag (the commit SHA shown in
   the CI run).

The CD workflow applies the manifests, updates the Deployment to the requested
image, and waits for the rollout to finish.

## Kubernetes quick start

Using minikube as an example:

```powershell
minikube start
kubectl apply -k k8s
kubectl -n devops-lab get pods,svc
kubectl -n devops-lab port-forward service/devops-lab-api 8080:80
```

Open <http://localhost:8080>. To use a locally built image, load it into the
cluster and make sure the Deployment uses that tag:

```powershell
minikube image load devops-lab-api:local
```

See [docs/03-kubernetes.md](docs/03-kubernetes.md) for rollout, debugging, and
exercises.

## Terraform ECR

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

This creates a private ECR repository with scan-on-push, immutable tags, and a
lifecycle policy. It is optional for the main CI/CD flow, which uses GHCR.

## Learning roadmap

| Week | Topic                  | Files                          | Outcome                                      |
| ---- | ---------------------- | ------------------------------ | -------------------------------------------- |
| 1    | Containers             | `Dockerfile`, `.dockerignore`  | Build, run, inspect, and slim an image       |
| 2    | CI                     | `.github/workflows/ci.yml`     | Automated lint, test, build, publish         |
| 3    | Kubernetes             | `k8s/`                         | Deploy, probe, scale, and roll back          |
| 4    | CD                     | `.github/workflows/cd.yml`     | Release a SHA-tagged image safely            |
| 5    | Infrastructure as Code | `terraform/`                   | Plan and apply a real AWS resource           |
| 6    | Operations and demo    | `docs/05-...`, `k8s/optional`  | Add monitoring, present the full pipeline    |

Detailed lessons and exercises live in [`docs/`](docs/):

- [01 - Containers with Docker](docs/01-docker.md)
- [02 - CI/CD with GitHub Actions](docs/02-ci-cd.md)
- [03 - Kubernetes](docs/03-kubernetes.md)
- [04 - Infrastructure as Code with Terraform](docs/04-terraform.md)
- [05 - Operations and next steps](docs/05-operations.md)
- [Teaching guide](docs/teaching-guide.md)

## Teaching this project

The [teaching guide](docs/teaching-guide.md) contains a six-week plan, a 90-minute
session structure, milestones, and an assessment rubric. Recommended rhythm:

1. Explain the concept and show the broken or manual version.
2. Demo the working pipeline.
3. Give learners a small, verifiable exercise.
4. Review together and connect it to a real job task.

## Cost and cleanup

- GHCR is free for public images within GitHub's limits.
- ECR charges for storage; run `terraform destroy` after the lesson.
- Delete the Kubernetes namespace with `kubectl delete -k k8s`.
- Do not commit `.env`, kubeconfig, Terraform state, or cloud credentials.
