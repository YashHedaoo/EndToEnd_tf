# Dynatrace OneAgent as an ECS Daemon Service on AWS ECS (EC2 launch type)

This repository contains modularized, production-grade, and security-scanned Terraform configurations to deploy the **Dynatrace OneAgent as an ECS Daemon Service** on an AWS ECS Cluster using the EC2 launch type only.

---

## Observability Architecture

This architecture deploys exactly one OneAgent monitoring container on every EC2 container host instance. The OneAgent hooks into the container runtime (Docker/Containerd) at the host level, auto-discovering all services and running tasks on the instance.

```mermaid
graph TD
    subgraph Dynatrace SaaS
        DT[Dynatrace SaaS Control Plane]
    end

    subgraph AWS ECS Cluster (EC2)
        subgraph EC2 Host 1
            OA1[Dynatrace OneAgent Container]
            Task1[Application Tasks]
        end

        subgraph EC2 Host 2
            OA2[Dynatrace OneAgent Container]
            Task2[Application Tasks]
        end
    end

    OA1 -->|Proc / Host mount monitoring| Task1
    OA2 -->|Proc / Host mount monitoring| Task2
    OA1 -->|HTTPS Port 443 Egress| DT
    OA2 -->|HTTPS Port 443 Egress| DT
```

---

## Folder Structure

```text
terraform-dynatrace-ecs/
├── README.md                  # Project documentation, guides, and architecture
├── main.tf                    # Root orchestrator mapping modules
├── providers.tf               # Root provider definition (AWS only)
├── versions.tf                # Versions and constraints for CLI and provider
├── variables.tf               # Root input variable definitions
├── outputs.tf                 # Global outputs
├── backend.tf                 # Production S3 remote state and DynamoDB lock table
│
├── modules/
│   ├── networking/            # VPC, public/private subnets, security groups
│   ├── ecs-cluster/           # ECS Cluster configuration
│   ├── ecs-capacity/          # Launch templates, Auto Scaling, and Capacity Providers
│   ├── iam/                   # Instance profiles and execution/task roles
│   ├── secrets/               # Secrets Manager parameters for Dynatrace credentials
│   └── oneagent/              # Task definition and DAEMON scheduling service
│
├── environments/
│   ├── dev/                   # Dev environment stage
│   ├── test/                  # Test environment stage
│   └── stage/                 # Stage environment stage
│
├── tests/
│   ├── terraform/             # Native HCL plan tests and assertions
│   └── terratest/             # Go-based integration tests
```

---

## Secrets Management

Dynatrace access details are stored securely in **AWS Secrets Manager** to avoid plain-text credential leaks:
*   `dynatrace-api-url-${environment}`
*   `dynatrace-paas-token-${environment}`

The ECS Task Execution Role has direct permissions (`secretsmanager:GetSecretValue`) to inject these parameters into the OneAgent container at boot time.

---

## Environment Promotion Flow

Wrapper configurations partition execution contexts across `dev`, `test`, and `stage` environments:

```text
Commit Changes
      │
      ▼
Deploy DEV ──► Validate OneAgent Ingestion ──► Approve Gate ──► Deploy TEST ──► Approve Gate ──► Deploy STAGE
```

To deploy an environment:
1.  Navigate to the target wrapper folder:
    ```bash
    cd environments/dev/
    ```
2.  Configure variables (copy `terraform.tfvars.example` to `terraform.tfvars` and edit):
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
3.  Deploy:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

---

## Automated Validation & Tests

### 1. HCL Validation Scan
Run native assertions validating cluster formatting, security profiles, and task configuration:
```bash
terraform test -test-directory=tests/terraform
```

### 2. Go Integration Tests
Run Terratest suite to compile plan topologies offline:
```bash
cd tests/terratest
go test -v
```

---

## Troubleshooting Guide

### 1. OneAgent Service Cannot Start
*   **Cause**: Invalid tokens or URL in Secrets Manager.
*   **Fix**: Check CloudWatch Logs under `/ecs/dynatrace-oneagent-${environment}` for authentication errors.

### 2. Missing Host Metrics in Dynatrace
*   **Cause**: Host instances did not boot successfully or join the cluster.
*   **Fix**: Check EC2 console to ensure instances are running and registered in the ECS capacity provider.

---

## Rollback Guide

To decommission the OneAgent Daemon and clean up the infrastructure environment cleanly:
1.  Navigate to your target environment folder (e.g. `environments/dev`).
2.  Run the destroy command:
    ```bash
    terraform destroy -auto-approve
    ```
    *Note: Secrets are deleted immediately (recovery window set to 0 days) ensuring cleanup and allowing clean re-runs.*
