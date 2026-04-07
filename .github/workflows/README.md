# GKE Deployment Pipeline

Deploys Nexus to GKE via `workflow_dispatch` using Workload Identity Federation and Kustomize.

## Pipeline steps

1. Patch the Workload Identity annotation in `serviceaccount-patch.yaml` with `GCP_PROJECT_ID`
2. Apply the kustomize production overlay (`kubectl apply -k`)
3. Wait for rollout to complete (300 s timeout)

## Required IAM roles

- `roles/container.admin`
- `roles/iam.workloadIdentityUser`

## GitHub secrets

| Secret | Description |
|---|---|
| `GCP_PROJECT_ID` | GCP project ID |
| `GKE_CLUSTER_NAME` | GKE cluster name |
| `GKE_ZONE` | Cluster zone (e.g. `us-central1-a`) |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Federation provider resource name |
| `GCP_SERVICE_ACCOUNT` | Service account email used by the pipeline |
