.PHONY: help install lint test run build up down logs k8s-apply k8s-delete tf-init tf-fmt tf-validate

help:
	@echo "install      Install development dependencies"
	@echo "lint         Run flake8"
	@echo "test         Run pytest"
	@echo "run          Run the app locally on port 8000"
	@echo "build        Build the Docker image"
	@echo "up           Start the stack with Docker Compose"
	@echo "down         Stop the Docker Compose stack"
	@echo "logs         Follow Docker Compose logs"
	@echo "k8s-apply    Apply Kubernetes manifests"
	@echo "k8s-delete   Delete Kubernetes resources"
	@echo "tf-init      Initialize Terraform"
	@echo "tf-fmt       Format Terraform files"
	@echo "tf-validate  Validate Terraform configuration"

install:
	pip install -r requirements-dev.txt

lint:
	flake8 app tests

test:
	python -m pytest -q

run:
	python -m app.main

build:
	docker build -t devops-lab-api:local .

up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f

k8s-apply:
	kubectl apply -k k8s

k8s-delete:
	kubectl delete -k k8s

tf-init:
	terraform -chdir=terraform init

tf-fmt:
	terraform -chdir=terraform fmt -recursive

tf-validate:
	terraform -chdir=terraform validate
