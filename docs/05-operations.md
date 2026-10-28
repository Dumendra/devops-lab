# Lesson 5: Operations, security, and next steps

## Learning goals

By the end of this lesson you can:

- Describe the three pillars of observability and apply them to this service.
- Define a simple SLI and SLO for the API.
- List the security controls already present and the gaps to close next.
- Choose a realistic next project that matches a DevOps job description.

## Observability

The three pillars:

- **Logs**: discrete events. Read them with `kubectl logs` or ship them to a
  central system.
- **Metrics**: numeric time series. Useful for rates, saturation, and errors.
- **Traces**: the path of a single request across services.

A simple starting method is RED for request-driven services:

- **Rate**: requests per second.
- **Errors**: failed requests per second.
- **Duration**: latency distribution.

Kubernetes adds USE for resources: utilization, saturation, errors.

### Logs in this project

```powershell
kubectl -n devops-lab logs -f deployment/devops-lab-api
```

Gunicorn writes access logs to stdout, which is the container-native pattern.
In production, prefer structured JSON logs with request IDs, and ship them to a
central store. Never log secrets or full authorization headers.

### Metrics exercise

1. Add a `/metrics` endpoint with `prometheus-flask-exporter` or a small
   hand-written Prometheus client.
2. Install kube-prometheus-stack in the cluster.
3. Create a ServiceMonitor or scrape annotation for the API.
4. Graph request rate and p95 latency in Grafana.
5. Add an alert for a sustained 5xx rate.

### SLI and SLO example

- SLI: proportion of successful requests to `/` over a 5-minute window.
- SLO: 99.5 percent availability over 30 days.
- Error budget: the remaining 0.5 percent. Discuss what happens when it is spent.

Health checks alone do not measure user experience. A service can be "healthy"
and still return wrong or slow responses, which is why the SLI uses a real user
request instead of `/health`.

## Security checklist

Already present:

- Non-root container user.
- Multi-stage image with no build tools in production.
- `readOnlyRootFilesystem`, dropped capabilities, no privilege escalation.
- Readiness and liveness probes.
- Immutable image tags and scan-on-push in ECR.
- Dependabot for dependencies, Docker, Actions, and Terraform.
- Least-privilege workflow permissions.

Still to do, as exercises:

- Pin GitHub Actions to commit SHAs, not moving major tags.
- Generate an SBOM and sign images (Syft, Cosign).
- Scan images in CI with Trivy or Docker Scout.
- Use External Secrets or Sealed Secrets instead of plain Kubernetes Secrets.
- Add NetworkPolicies and a PodDisruptionBudget.
- Restrict the cluster API endpoint and use RBAC per team.
- Enable audit logging in the cluster and the registry.
- Add a bug bounty or responsible disclosure policy if the repo is public.

## GitOps and the next architecture step

The CD workflow pushes changes with `kubectl`. GitOps flips the direction: a
controller in the cluster watches a Git repository and reconciles the desired
state.

Try this next:

1. Install Argo CD or Flux in a local cluster.
2. Move the Kubernetes manifests to a deployment repository or an overlay
   directory.
3. Point the controller at `main` and watch it sync.
4. Change the image tag in Git and watch the rollout happen without CI holding
   cluster credentials.

This removes long-lived kubeconfig secrets from CI and makes every change
reviewable in Git.

## Multi-environment layout

A common progression:

```text
k8s/
  base/
  overlays/
    dev/
    staging/
    prod/
```

Each overlay sets replicas, resources, hostnames, and image tags. Promote the
same image SHA through environments instead of rebuilding per environment.

## Career map

| Level        | What employers expect                                             |
| ------------ | ----------------------------------------------------------------- |
| Entry        | Linux, Git, one cloud, Docker, basic CI, troubleshooting          |
| Mid          | Kubernetes, Terraform, pipelines, monitoring, on-call, scripting  |
| Senior       | Design trade-offs, reliability, cost, security, mentoring         |

Use this repository as a portfolio story:

- Problem: containerize and ship a service repeatably.
- Constraints: small team, no manual steps, immutable releases.
- Solution: CI with tests and scans, SHA-tagged images, reviewed CD, K8s
  probes, Terraform-managed registry.
- Evidence: links to workflows, manifests, and lessons.
- Reflection: what you would change for scale, cost, and compliance.

Practice explaining:

- Why deploy by SHA rather than `latest`.
- How readiness differs from liveness.
- What happens when a rollout fails.
- How state locking prevents corrupt infrastructure.
- How you would detect and respond to a bad release.

## Suggested project extensions

In increasing difficulty:

1. Add a database with a managed service and a migration step.
2. Add Prometheus and Grafana, then define one alert and one SLO.
3. Split into two services and practice service discovery and tracing.
4. Add GitOps with Argo CD and environment overlays.
5. Add image signing and policy enforcement (Cosign, Kyverno).
6. Add a cloud load balancer, DNS, and TLS with cert-manager.
7. Run a game day: break the image tag, the probe, and the database, then
   practice detection and rollback.

## Cleanup

```powershell
terraform -chdir=terraform destroy
kubectl delete -k k8s
minikube stop
```

Review cloud billing after every lesson. Delete unused container images and
clusters; they are common sources of surprise charges.
