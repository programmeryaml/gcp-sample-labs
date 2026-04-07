# Terraform Guide – GCP Infrastructure Setup

This guide walks through every step needed to set up Terraform locally,
configure a remote backend, preview changes, and apply them to the GCP
environment for this project.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Authentication](#2-authentication)
3. [Remote State Backend (GCS)](#3-remote-state-backend-gcs)
4. [Initialise Terraform](#4-initialise-terraform)
5. [Plan (dry run)](#5-plan-dry-run)
6. [Save a Plan File](#6-save-a-plan-file)
7. [Apply](#7-apply)
8. [Useful Commands](#8-useful-commands)
9. [Variable Reference](#9-variable-reference)
10. [Outputs Reference](#10-outputs-reference)

---

## 1 – Prerequisites

| Tool | Minimum version | Install |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` | `brew install terraform` / official installer |
| [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install) | any recent | official installer |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | matches your GKE version | `gcloud components install kubectl` |

Verify your installations:

```bash
terraform version   # must print >= 1.5.x
gcloud version
kubectl version --client
```

---

## 2 – Authentication

Terraform uses **Application Default Credentials (ADC)** to authenticate to GCP.
Run the following once on your workstation:

```bash
gcloud auth application-default login
```

This opens a browser window. After logging in, credentials are cached at
`~/.config/gcloud/application_default_credentials.json`.

> **Service accounts in CI/CD**
> In automated pipelines (GitHub Actions, Cloud Build) set the
> `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of a
> downloaded service-account key JSON, or use Workload Identity Federation
> so that no static key is needed.

Also set your working project:

```bash
export PROJECT_ID=my-gcp-project   # replace with your real project ID
gcloud config set project $PROJECT_ID
```

---

## 3 – Remote State Backend (GCS)

Storing Terraform state in a GCS bucket ensures the state is shared across
team members and is not lost if your laptop is wiped.

### 3.1 Create the state bucket (one-time)

```bash
# Choose a unique bucket name; label it clearly as a Terraform state bucket.
export TF_STATE_BUCKET="${PROJECT_ID}-tf-state"

gsutil mb -p $PROJECT_ID -l us-central1 gs://${TF_STATE_BUCKET}

# Enable versioning so you can roll back to a previous state if needed.
gsutil versioning set on gs://${TF_STATE_BUCKET}
```

### 3.2 Enable the backend in `provider.tf`

Uncomment and fill in the `backend "gcs"` block in `terraform/provider.tf`:

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "my-gcp-project-tf-state"   # your TF_STATE_BUCKET value
    prefix = "terraform/nexus"
  }
}
```

> **Tip:** commit the updated `provider.tf` so every team member and your CI
> pipeline uses the same backend automatically.

---

## 4 – Initialise Terraform

Run `terraform init` from the `terraform/` directory whenever you:
* set up the project for the first time,
* switch to a new backend, or
* add / update provider versions.

```bash
cd terraform

terraform init
```

Expected output (abbreviated):

```
Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 5.0"...
- Installing hashicorp/google v5.x.x...
- Installed hashicorp/google v5.x.x (signed by HashiCorp)

Terraform has been successfully initialized!
```

### Upgrade providers

```bash
terraform init -upgrade   # re-downloads providers to newest allowed version
```

---

## 5 – Plan (dry run)

`terraform plan` compares the desired state (your `.tf` files) with the current
GCP resources and prints a diff **without making any changes**.

```bash
cd terraform

terraform plan -var="project_id=${PROJECT_ID}"
```

Key symbols in the output:

| Symbol | Meaning |
|---|---|
| `+` green | resource will be **created** |
| `~` yellow | resource will be **updated in-place** |
| `-` red | resource will be **destroyed** |
| `-/+` | resource will be **replaced** (destroy then create) |

Example snippet:

```
Terraform will perform the following actions:

  # google_container_cluster.nexus_cluster will be created
  + resource "google_container_cluster" "nexus_cluster" {
      + name     = "nexus-cluster"
      + location = "us-central1-a"
      ...
    }

  # google_storage_bucket.nexus_artifacts will be created
  + resource "google_storage_bucket" "nexus_artifacts" {
      + name     = "my-gcp-project-nexus-artifacts"
      + location = "US-CENTRAL1"
      ...
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

### Override additional variables on the command line

```bash
terraform plan \
  -var="project_id=${PROJECT_ID}" \
  -var="region=us-central1" \
  -var="cluster_name=nexus-cluster" \
  -var="gcs_bucket_name=nexus-artifacts"
```

### Use a `.tfvars` file (recommended for teams)

Create `terraform/terraform.tfvars` (do **not** commit this file if it
contains sensitive values – add it to `.gitignore`):

```hcl
project_id   = "my-gcp-project"
region       = "us-central1"
zone         = "us-central1-a"
cluster_name = "nexus-cluster"
```

Then run:

```bash
terraform plan   # automatically loads terraform.tfvars
```

---

## 6 – Save a Plan File

Saving the plan to a file guarantees that the exact diff you reviewed is what
gets applied – no surprises from infrastructure changes in between.

```bash
cd terraform

# Save the plan
terraform plan \
  -var="project_id=${PROJECT_ID}" \
  -out=nexus.tfplan

# Inspect the saved plan in human-readable form
terraform show nexus.tfplan
```

The `.tfplan` file is a binary; always review it with `terraform show` before
applying.

---

## 7 – Apply

### Apply from a saved plan (recommended)

```bash
cd terraform

terraform apply nexus.tfplan
```

Terraform will execute exactly the changes shown in the saved plan and will
**not** prompt for confirmation.

### Apply interactively (ad-hoc)

```bash
cd terraform

terraform apply -var="project_id=${PROJECT_ID}"
```

Terraform will display the plan and ask:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter to proceed.

### Configure `kubectl` after apply

Once the GKE cluster is created, fetch the cluster credentials:

```bash
$(terraform output -raw kubeconfig_command)
# equivalent to:
gcloud container clusters get-credentials nexus-cluster \
  --zone us-central1-a \
  --project ${PROJECT_ID}
```

Verify access:

```bash
kubectl get nodes
```

---

## 8 – Useful Commands

| Command | Purpose |
|---|---|
| `terraform init` | Download providers and configure backend |
| `terraform fmt` | Auto-format all `.tf` files |
| `terraform validate` | Check configuration syntax without contacting GCP |
| `terraform plan` | Show what would change |
| `terraform plan -out=FILE` | Save the plan to a file |
| `terraform show FILE` | Human-readable view of a saved plan |
| `terraform apply FILE` | Apply a previously saved plan |
| `terraform apply -auto-approve` | Apply without the interactive prompt (CI use only) |
| `terraform output` | Print all output values |
| `terraform output -raw <name>` | Print a single output value (no quotes) |
| `terraform state list` | List all resources tracked in state |
| `terraform state show <resource>` | Inspect a specific tracked resource |
| `terraform destroy` | Tear down all managed resources (use with caution) |

---

## 9 – Variable Reference

All variables are defined in `variables.tf`.

| Variable | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | *(required)* | GCP project ID |
| `region` | `string` | `us-central1` | GCP region for the GCS bucket |
| `zone` | `string` | `us-central1-a` | Zone for the GKE cluster and node pool |
| `cluster_name` | `string` | `nexus-cluster` | Name of the GKE cluster |
| `gcs_bucket_name` | `string` | `nexus-artifacts` | Suffix for the GCS bucket name (`<project_id>-<suffix>`) |
| `nexus_sa_name` | `string` | `nexus-sa` | GCP service account ID for Nexus |
| `kubernetes_namespace` | `string` | `nexus` | Kubernetes namespace where Nexus runs |
| `kubernetes_sa_name` | `string` | `nexus` | Kubernetes service account name |
| `artifact_retention_days` | `number` | `0` | Days before GCS objects are deleted (`0` = disabled) |

---

## 10 – Outputs Reference

After a successful `terraform apply`, the following values are available:

| Output | Description |
|---|---|
| `gke_cluster_name` | Name of the created GKE cluster |
| `gke_cluster_endpoint` | API server endpoint (marked sensitive) |
| `gcs_bucket_name` | Full GCS bucket name (use this in the Nexus blob store config) |
| `nexus_service_account_email` | GCP SA email for the Workload Identity annotation |
| `kubeconfig_command` | Ready-to-run `gcloud` command to configure `kubectl` |

Retrieve them any time with:

```bash
terraform output                           # all outputs
terraform output gcs_bucket_name          # single output
terraform output -raw kubeconfig_command  # single output without quotes
```
