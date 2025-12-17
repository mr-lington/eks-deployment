# AWS EKS Production Deployment with Terraform

##  Project Overview
This repository documents the **end-to-end design, deployment, security, scaling, and troubleshooting** of a **production-ready Amazon EKS cluster** built using **Terraform, Helm, and Kubernetes best practices**.

This project goes beyond simply “getting EKS running” and focuses on **real DevOps engineering work**, including:

- Infrastructure as Code (Terraform)
- Secure IAM & AWS Pod Identity
- Kubernetes networking & storage
- Autoscaling & observability
- Cost-aware architecture
- Real-world troubleshooting & recovery

>  **Docker image build is intentionally excluded** to keep the focus on **platform & infrastructure engineering**, not application packaging.

---

## Architecture Summary

### Core Components
- Amazon EKS (Managed Kubernetes)
- Terraform (Infrastructure as Code)
- Helm (Kubernetes package management)
- AWS VPC (Public & Private subnets)
- Application Load Balancer (ALB)
- NGINX Ingress Controller
- Cluster Autoscaler
- Metrics Server & HPA
- EBS & EFS CSI Drivers
- AWS Secrets Manager (via CSI)
- Pod Identity (IRSA successor)
- Cert-Manager (TLS automation)

### Kubernetes Namespaces
- `kube-system`
- `ingress`
- `cert-manager`
- `prod-frontend`

---

##  Repository Structure

```text
eks-deployment/
├── terraform/
│   ├── 1-locals.tf
│   ├── 2-vpc.tf
│   ├── 3-provider.tf
│   ├── 4-subnets.tf
│   ├── 5-igw.tf
│   ├── 6-nat-gw.tf
│   ├── 8-eks.tf
│   ├── 9-sso.tf
│   ├── 10-helm-provider.tf
│   ├── 11-metric-server.tf
│   ├── 12-cluster-autoscaler-irsa.tf
│   ├── 13-alb.tf
│   ├── 14-nginx-controller.tf
│   ├── 15-cert-manager.tf
│   ├── 16-ebs-csi-driver.tf
│   ├── 17-efs-csi-driver.tf
│   ├── 18-secrets-store-csi-driver.tf
│   └── output.tf
│
├── k8s/
│   ├── ns.yaml
│   ├── app.yaml
│   ├── alb-app.yaml
│   ├── ingress-app.yaml
│   ├── nginx-deployment.yaml
│   ├── busybox-deployment.yaml
│   ├── load-generator.yaml
│   ├── hpa.yaml
│   ├── pvc.yaml
│   ├── statefulset.yaml
│   └── secret-provider-class.yaml
│
├── scripts/
│   ├── create-s3-bucket.sh
│   └── delete-s3-bucket.sh
│
└── README.md
```
# Infrastructure Deployment Flow – AWS EKS (Production)
## Remote State & Bootstrap

- S3 backend used for Terraform remote state
- State locking enabled to prevent concurrent executions
- Custom scripts for safe S3 bucket lifecycle management

```bash
./scripts/create-s3-bucket.sh
terraform init
```
## Networking (VPC)
- Custom VPC with CIDR planning
- Public subnets for ingress components (ALB / Ingress)
- Private subnets for EKS worker nodes
- NAT Gateway for outbound internet access
- Internet Gateway for ALB traffic
### Benefits
- No public IPs on worker nodes
- Reduced attack surface
- Lower security risk

## Amazon EKS Cluster
- Managed EKS cluster provisioned via Terraform
- Managed node groups
- KMS encryption enabled for Kubernetes secrets
- Control plane logging enabled
- AWS SSO-based access configuration

## Core Kubernetes Add-ons
Installed using Terraform + Helm:
- VPC CNI
- kube-proxy
- kube-proxy
- CoreDNS
- Metrics Server
- Pod Identity Agent
---

## Ingress & Traffic Management
- AWS Load Balancer Controller
- Application Load Balancer (ALB)
- NGINX Ingress Controller
- Path-based and host-based routing
- TLS certificates automated using Cert-Manager
---
## Autoscaling & Observability
- Metrics Server for resource metrics
- Horizontal Pod Autoscaler (HPA)
- Cluster Autoscaler for node scaling
- Load generator used to validate scaling behaviour

---
## Storage Architecture
EBS CSI Driver
- Block storage
- Used for StatefulSets and single-pod persistence
EFS CSI Driver
- Shared filesystem
- Multi-pod access
- Demonstrates ReadWriteMany volumes
---

## Secrets Management (Production-Grade)
- AWS Secrets Manager used as the source of truth
- Secrets Store CSI Driver installed
- AWS provider configured
- Pod Identity used instead of static credentials
- Secrets mounted as volumes and injected as environment variables

No secrets stored in:
- GitHub
- Terraform state
- Kubernetes manifests
---
## Security Best Practices
- Zero hardcoded credentials
- Pod Identity (no IAM access keys)
- Least-privilege IAM policies
- Private worker nodes only
- TLS everywhere via Cert-Manager
- Namespace isolation
## Cost-Saving Measures

This infrastructure was designed with cost efficiency in mind:
 Private Nodes Only  
No public IP costs and reduced attack surface
- Controlled Autoscaling  
Node group scaling limits enforced
- Right-Sized Resources  
HPA prevents over-provisioning
- Shared Storage with EFS  
Avoids multiple EBS volumes
- Managed AWS Services  
Lower operational overhead
---

## Troubleshooting & Debugging
### Cluster & Nodes
```bash
kubectl get nodes
kubectl describe node <node-name>
kubectl get pods -A -o wide
kubectl get pods -A -o wide | awk '{print $8}' | sort | uniq -c
```
