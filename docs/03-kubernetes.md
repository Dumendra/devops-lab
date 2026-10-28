# Lesson 3: Kubernetes

## Learning goals

By the end of this lesson you can:

- Map application concepts to Kubernetes objects.
- Deploy the API with Kustomize and reach it through a Service.
- Read probes, resource requests, and security contexts.
- Perform and verify a rolling update, then roll back.
- Debug a pod that is not becoming ready.

## Concepts

| Concept        | What it means here                                         |
| -------------- | ---------------------------------------------------------- |
| Cluster        | The Kubernetes control plane plus worker nodes             |
| Pod            | One or more containers; the smallest deployable unit       |
| Deployment     | Desired replica count and rollout strategy for pods        |
| Service        | Stable virtual IP and DNS name that load-balances pods     |
| Namespace      | Logical isolation boundary (`devops-lab`)                  |
| Kustomize      | Overlays and shared settings without templating            |
| Probe          | Health check that controls traffic and restarts            |

The Deployment labels `app.kubernetes.io/name: devops-lab-api`. The Service uses
the same label as its selector, so it only routes to pods from this app.

## Get a local cluster

Pick one:

```powershell
# Option A: minikube
minikube start

# Option B: kind
kind create cluster --name devops-lab

# Option C: enable Kubernetes in Docker Desktop settings
kubectl config current-context
```

## Deploy

```powershell
kubectl apply -k k8s
kubectl -n devops-lab get pods,svc
```

The Deployment references `devops-lab-api:local` with
`imagePullPolicy: IfNotPresent`. A cluster cannot see your local Docker image
unless you load it:

```powershell
# minikube
minikube image load devops-lab-api:local

# kind
kind load docker-image devops-lab-api:local --name devops-lab
```

Then restart the rollout if pods were already failing:

```powershell
kubectl -n devops-lab rollout restart deployment/devops-lab-api
kubectl -n devops-lab rollout status deployment/devops-lab-api
```

## Reach the service

```powershell
kubectl -n devops-lab port-forward service/devops-lab-api 8080:80
```

In another terminal:

```powershell
curl http://localhost:8080/health
curl http://localhost:8080/
```

`port-forward` is for debugging only. In a real cluster you would expose the
Service through an Ingress or a cloud load balancer.

## Probes

- **Readiness** decides whether the pod receives traffic. A failing readiness
  probe removes the pod from Service endpoints without restarting it.
- **Liveness** decides whether the kubelet restarts the container.
- **Startup** (not used here) gives slow-starting apps time before liveness
  checks begin.

Good probes reflect real dependencies. A `/health` that always returns 200
without checking anything is only a shallow check.

## Rolling update and rollback

Build and load a new version:

```powershell
docker build --build-arg APP_VERSION=2.0.0 -t devops-lab-api:v2 .
minikube image load devops-lab-api:v2

kubectl -n devops-lab set image deployment/devops-lab-api api=devops-lab-api:v2
kubectl -n devops-lab rollout status deployment/devops-lab-api
kubectl -n devops-lab rollout history deployment/devops-lab-api
```

Confirm the version through the port-forward:

```powershell
curl http://localhost:8080/
```

Roll back:

```powershell
kubectl -n devops-lab rollout undo deployment/devops-lab-api
```

The strategy `maxUnavailable: 0` and `maxSurge: 1` keeps capacity during the
rollout, and the readiness probe prevents traffic from reaching unready pods.

## Debugging workflow

```powershell
kubectl -n devops-lab get pods -o wide
kubectl -n devops-lab describe pod <pod-name>
kubectl -n devops-lab logs <pod-name>
kubectl -n devops-lab get events --sort-by=.lastTimestamp
kubectl -n devops-lab exec -it <pod-name> -- sh
```

Order matters: events often explain image pull, scheduling, and probe failures
before logs show anything.

## Exercise 3.1: Break readiness

Patch the readiness path to a route that does not exist:

```powershell
kubectl -n devops-lab patch deployment devops-lab-api --type=json `
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/missing"}]'
```

Watch pods stay `0/1` ready and observe that the Service has no endpoints:

```powershell
kubectl -n devops-lab get pods
kubectl -n devops-lab get endpoints devops-lab-api
```

Fix it:

```powershell
kubectl -n devops-lab rollout undo deployment/devops-lab-api
```

Why did the pod not restart? Which probe would restart it?

## Exercise 3.2: Resources

Set requests to `500m` CPU and one replica, then deploy to a small cluster.
Observe scheduling. Reset afterward. Explain the difference between requests and
limits using the kubelet's behavior under CPU pressure.

## Exercise 3.3: Scaling

```powershell
kubectl -n devops-lab scale deployment/devops-lab-api --replicas=4
kubectl -n devops-lab get pods
kubectl -n devops-lab scale deployment/devops-lab-api --replicas=2
```

Then apply the optional HPA after installing a metrics server:

```powershell
kubectl apply -f k8s/optional/hpa.yaml
kubectl -n devops-lab get hpa
```

## Exercise 3.4: Ingress

Install an ingress controller (for minikube: `minikube addons enable ingress`),
apply `k8s/optional/ingress.yaml`, and map `devops-lab.local` to the ingress IP
in your hosts file. Explain why DNS or host mapping is required.

## Exercise 3.5: Production guardrails

Add and test one of the following:

- A PodDisruptionBudget with `minAvailable: 1`.
- A NetworkPolicy that allows ingress only from the ingress controller.
- A ResourceQuota and LimitRange for the namespace.
- Separate dev and prod overlays under `k8s/overlays/`.

## Cleanup

```powershell
kubectl delete -k k8s
minikube stop
```

## Checkpoint

You are done when you can:

- Deploy from scratch and explain every object.
- Show a pod becoming ready only when the readiness probe passes.
- Update to a new image and roll back with the rollout commands.
- Debug an image pull failure and a probe failure without guessing.
