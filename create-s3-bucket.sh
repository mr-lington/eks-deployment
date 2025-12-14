#!/bin/bash
#set -euo pipefail

# === Config ===
BUCKET_NAME="eks-statefile-bucket1"
AWS_REGION="eu-west-3"
AWS_PROFILE="lington"
CLUSTER_NAME="staging-demo-eks"   # must match your EKS cluster name

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KMS_ALIAS_NAME="alias/eks/$CLUSTER_NAME"

echo ">> Using profile: $AWS_PROFILE, region: $AWS_REGION"
echo ">> Script root: $ROOT_DIR"

# # AWS SSO Login
# echo ">> Logging into AWS SSO for profile: $AWS_PROFILE"
# aws sso logout >/dev/null 2>&1 || true
# aws sso login --profile "$AWS_PROFILE"

# export AWS_PROFILE="$AWS_PROFILE"
# export AWS_SDK_LOAD_CONFIG=1

# Clean up existing KMS alias (if any exist)
echo ">> Checking/removing existing KMS alias (if present): $KMS_ALIAS_NAME"
aws kms delete-alias \
  --alias-name "$KMS_ALIAS_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  2>/dev/null && \
  echo "   -> Old KMS alias deleted (it existed before)." || \
  echo "   -> No existing alias to delete or not required, continuing..."

# Create/ensure S3 bucket for Terraform state
echo ">> Creating S3 bucket for Terraform state: $BUCKET_NAME (region: $AWS_REGION)"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" \
  2>/dev/null && \
  echo "   -> Bucket created." || \
  echo "   -> Bucket may already exist, continuing..."

echo ">> Enabling versioning on bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --versioning-configuration Status=Enabled

# Terraform – networking + EKS
echo ">> Running Terraform for networking + EKS..."
cd "$ROOT_DIR/netwoking"

terraform init #-upgrade
terraform fmt
terraform validate
terraform apply -auto-approve

# Configure kubectl for EKS cluster
cd "$ROOT_DIR"

echo ">> Updating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --profile "$AWS_PROFILE"

# create docker pull secret credentials
kubectl create secret docker-registry dockercded \
  --docker-username=lington \
  --docker-password='@Darboy123' \
  --docker-server=https://index.docker.io/v1/ \
  


echo ">> Verifying cluster connectivity..."
kubectl cluster-info
kubectl get nodes



# Apply Kubernetes manifests
echo ">> Applying Namespaces..."
kubectl apply -f "$ROOT_DIR/k8s/namespace/"

echo ">> Deploying Nginx demo app + Service..."
#kubectl apply -f "$ROOT_DIR/k8s/app/"
# kubectl apply -f "$ROOT_DIR/k8s/ingress-app/"
# #kubectl apply -f "$ROOT_DIR/k8s/cert-nginx-ingres/"  #using nginx external ingress controller
# kubectl apply -f "$ROOT_DIR/k8s/ebs-statefulset/"  # to deploy statefulset
# kubectl apply -f "$ROOT_DIR/k8s/efs-deployment/"   # for deployment of efs

echo ">> Applying HPA..."
kubectl apply -f "$ROOT_DIR/k8s/hpa/"