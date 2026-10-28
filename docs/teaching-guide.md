# Teaching Guide

This guide turns the repository into a six-week course for one learner, a small
cohort, or a mentoring relationship. Every week produces a visible artifact that
can go into a portfolio.

## Audience

Suitable for:

- Career switchers with basic Linux and Git knowledge.
- Junior developers moving toward platform or DevOps work.
- Teams standardizing their delivery process.

Assumed prerequisites:

- Comfort with a terminal.
- Basic Git (`clone`, `commit`, `push`, branches, pull requests).
- Ability to read a small Python file.

No prior Docker, Kubernetes, Terraform, or cloud experience is required.

## Learning outcomes

By the end, a learner can:

1. Containerize and run a service with a secure, multi-stage image.
2. Build a CI pipeline that tests, scans, and publishes immutable artifacts.
3. Deploy and troubleshoot the service on Kubernetes.
4. Provision infrastructure with Terraform and explain state management.
5. Define basic observability, security, and reliability practices.
6. Present an end-to-end delivery story with evidence and trade-offs.

## Format options

- **Six-week cohort**: one 90-minute live session plus two to four hours of
  practice per week.
- **Two-day intensive**: compress lessons 1 to 3 on day one and 4 to 6 on day
  two, with guided labs.
- **Self-paced**: follow the roadmap in the README and use the checkpoints as
  gates.

## Six-week plan

| Week | Pre-work                     | Live session                            | Practice                                  | Deliverable                     |
| ---- | ---------------------------- | --------------------------------------- | ----------------------------------------- | ------------------------------- |
| 0    | Install tools, create a repo | Orientation and architecture tour       | Run the app locally and with Compose      | Working local environment       |
| 1    | Read lesson 1                | Dockerfile walkthrough and demos        | Exercises 1.1 to 1.5                      | Smaller, non-root image          |
| 2    | Read lesson 2                | CI anatomy and GHCR publishing          | Add smoke test and Trivy scan             | Green CI with published image   |
| 3    | Read lesson 3                | Deploy, probe, rollout, rollback        | Probe and scaling labs                    | Running deployment in a cluster |
| 4    | Read lesson 4                | Terraform plan/apply and immutable ECR  | Apply, push an image, then destroy        | IaC module applied and cleaned  |
| 5    | Read lesson 5                | Observability, security, GitOps         | Add metrics and an alert                  | Dashboard or alert screenshot   |
| 6    | Prepare a demo               | Review and demo day                     | Present the pipeline and a failure story  | Portfolio-ready walkthrough     |

Milestones:

- **M0**: local app runs and tests pass.
- **M1**: image builds and runs as a non-root user.
- **M2**: CI is green and a SHA-tagged image exists in the registry.
- **M3**: the app runs in Kubernetes and survives a rollout and rollback.
- **M4**: Terraform creates and destroys the registry cleanly.
- **M5**: one metric, one log example, and one alert or SLO are documented.
- **M6**: a ten-minute demo with a failure and recovery narrative.

## 90-minute session template

1. **Recap and questions (10 min)**: learners state what they built and what
   broke.
2. **Concept (15 min)**: one core idea, one diagram, no tool tour.
3. **Instructor demo (15 min)**: show the working path, narrate decisions.
4. **Guided lab (30 min)**: learners repeat the demo with checkpoints.
5. **Break (5 min)**.
6. **Challenge (10 min)**: a small failure to diagnose, such as a bad probe or
   an immutable tag collision.
7. **Debrief and homework (5 min)**: capture the lesson and the next artifact.

Keep the demo environment ready before the session. Live-building from zero
usually consumes the entire lab time.

## Assessment rubric

Use four levels: needs work, approaching, meets, exceeds. Assess evidence, not
recall.

| Criteria         | Meets                                                        | Exceeds                                             |
| ---------------- | ------------------------------------------------------------ | --------------------------------------------------- |
| Containers       | Builds and runs the image; explains multi-stage and non-root | Reduces size and vulnerabilities with measurements  |
| CI/CD            | Pipeline tests, lints, builds, and publishes by SHA          | Adds scan, smoke test, and branch protection        |
| Kubernetes       | Deploys, probes, rolls out, and rolls back                    | Adds HPA, Ingress, or disruption guardrails         |
| IaC              | Plans, applies, and destroys ECR safely                      | Uses remote state and OIDC-based CI plan            |
| Operations       | Reads logs and explains probes and SLIs                      | Adds metrics, an alert, and an SLO discussion       |
| Communication    | Explains the pipeline clearly and honestly                   | Presents a failure, root cause, and improvement     |

## Demo day agenda

Give each learner ten minutes:

1. Architecture in one diagram (2 min).
2. CI run and registry artifact (2 min).
3. Deployment in Kubernetes and a rollout (2 min).
4. One failure they hit and how they diagnosed it (2 min).
5. What they would change next and why (2 min).

The failure story matters most. It shows debugging and communication skills that
interviewers look for.

## Adapting the material

For beginners:

- Keep the application unchanged.
- Pair on the Dockerfile and CI workflow.
- Provide the exact commands and ask learners to predict output before running.
- Replace the cloud lesson with LocalStack or a plan-only Terraform exercise.

For advanced learners:

- Add overlays and promote the same SHA through dev and prod.
- Require Trivy and actionlint to pass in CI.
- Add PodDisruptionBudgets and NetworkPolicies.
- Move to GitOps with Argo CD and remove cluster credentials from CI.
- Run a chaos exercise: wrong tag, failing readiness, and a bad resource limit.

## Common pitfalls

- **Docker image not found in the cluster**: the cluster has its own image store.
  Use `minikube image load` or `kind load docker-image`.
- **Image pull errors for a private registry**: create an image pull secret or
  make the package public for the lesson.
- **`latest` confusion**: always deploy a SHA and record it in the release note.
- **Probe paths that ignore reality**: a health check must reflect dependencies
  and startup behavior.
- **Terraform state in Git**: add `.gitignore` first, then teach the remote
  backend.
- **Surprise cloud costs**: set a budget alert and destroy resources at the end
  of every session.
- **CI permissions too broad**: start from read-only and add only what a job
  needs.

## Instructor checklist

Before the course:

- [ ] Create a sandbox cloud account and a budget alert.
- [ ] Confirm GHCR publishing works for the repository.
- [ ] Have a local cluster tested on the same OS as learners.
- [ ] Pre-pull base images to save bandwidth.
- [ ] Prepare a known-good rollback point.

Every session:

- [ ] Check that learners can run the previous week's artifact.
- [ ] Show the failure case before the fix.
- [ ] Leave five minutes for written reflection.
- [ ] Confirm cleanup of containers, clusters, and cloud resources.

Never share real credentials in slides, chat, or recordings. Use disposable
accounts, rotate anything that leaks, and teach learners to do the same.
