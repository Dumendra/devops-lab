# Lesson 2: CI/CD with GitHub Actions

## Learning goals

By the end of this lesson you can:

- Explain continuous integration and continuous delivery.
- Describe the anatomy of a GitHub Actions workflow.
- Read and modify the CI and CD workflows in this repository.
- Publish an immutable container image and deploy a specific version.

## CI vs CD

- **Continuous integration (CI)**: every change is automatically built and
  tested, so integration problems surface early.
- **Continuous delivery (CD)**: every change that passes CI is ready to deploy,
  with a human approving the release when needed.
- **Continuous deployment**: every passing change is deployed automatically.

This project uses CI on every push and manual CD triggered by a human.

## The pipeline

```text
push / pull request
        |
        v
  lint + test  --->  build image  --->  push image (tag = commit SHA)
                                             |
                                     manual CD workflow
                                             |
                                             v
                                         kubectl
```

## Anatomy of a workflow

Open [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

- `on`: the events that trigger the workflow.
- `permissions`: the least privilege the workflow needs. Publishing to GHCR
  requires `packages: write`.
- `jobs`: independent units that run on runners. `image` depends on `quality`
  through `needs`.
- `steps`: sequential commands and reusable actions.
- `if`: conditions, such as skipping the registry login on pull requests.

Useful concepts:

- **Runner**: the fresh VM that executes a job.
- **Action**: a reusable step such as `actions/checkout` or
  `docker/build-push-action`.
- **Cache**: `setup-python` caches dependencies; Buildx caches layers in GitHub
  Actions storage.
- **Artifact**: a file produced by a job. The container image is stored in a
  registry instead.

## Walk through the CI workflow

1. **quality** checks out the repository, installs Python 3.12, installs dev
   dependencies, runs Flake8, then Pytest.
2. **image** waits for `quality`. It lowercases the repository name because GHCR
   requires lowercase image names.
3. On non-PR events it logs in with the automatic `GITHUB_TOKEN`.
4. `docker/metadata-action` creates a tag from the commit SHA. Tags are
   immutable by convention: a SHA always refers to the same code.
5. Buildx builds and pushes the image with a layer cache.

Why not tag `latest`? A moving tag makes rollbacks ambiguous. Deploying by SHA
means you can always say exactly what is running.

## Walk through the CD workflow

Open [`.github/workflows/cd.yml`](../.github/workflows/cd.yml).

- It is triggered manually with `workflow_dispatch`.
- The `image_tag` input is normally a commit SHA from a successful CI run.
- It writes a kubeconfig from the `KUBE_CONFIG` secret.
- It applies the manifests with `kubectl apply -k k8s`.
- It updates the Deployment image and waits for the rollout.
- The `production` environment can require reviewers in repository settings.

Never commit a kubeconfig. Store it as a secret, and prefer short-lived
credentials or a cloud identity integration in real environments.

## Setup checklist

1. Push the repository to GitHub.
2. Keep the default `GITHUB_TOKEN` permission for packages enabled.
3. Push to `main` and watch the CI run.
4. Open **Packages** and confirm the SHA-tagged image exists.
5. Add a `KUBE_CONFIG` secret only when you have a cluster to deploy to.
6. Create a `production` environment with required reviewers for approvals.

## Exercises

### Exercise 2.1: Break the build on purpose

Introduce a failing test and push. Watch CI fail. Fix it and confirm a new image
appears. Write down which job failed and why.

### Exercise 2.2: Add a smoke test

Add a step that builds the image, runs it, and calls `/health` before pushing:

```yaml
- name: Build image for smoke test
  run: docker build -t devops-lab-api:test .

- name: Smoke test
  run: |
    docker run -d --name smoke -p 8000:8000 devops-lab-api:test
    sleep 2
    curl --fail http://localhost:8000/health
    docker rm -f smoke
```

This duplicates the build for clarity. As an advanced follow-up, set
`load: true` on the Buildx step and smoke-test the resulting image by tag.

### Exercise 2.3: Add a security scan

Add a vulnerability scan with Trivy or Docker Scout after the image is built.
Decide whether the build should fail on HIGH or CRITICAL findings, and justify
your choice.

### Exercise 2.4: Add linting for YAML

Add `actionlint` or `yamllint` to the quality job and fix any findings.

### Exercise 2.5: Branch protection

Enable branch protection on `main`: require the CI status check, require a pull
request, and disallow force pushes. Explain how this changes team behavior.

### Exercise 2.6: Deployment approval

Configure the `production` environment to require a reviewer. Trigger the CD
workflow and observe the pause before deployment.

## Debugging failed workflows

- Open the failed job and expand the failing step.
- Reproduce the command locally in the same order.
- Check the trigger and `if` conditions before assuming the command is wrong.
- For registry errors, check permissions, the image name case, and the tag.
- For deployment errors, run `kubectl describe` and `kubectl logs` against the
  cluster.

## Checkpoint

You are done when you can:

- Explain each job and step in CI.
- Build a SHA-tagged image on a pull request and publish one from `main`.
- Describe exactly how a specific image reaches Kubernetes.
- Explain why the kubeconfig is a secret, not a committed file.
