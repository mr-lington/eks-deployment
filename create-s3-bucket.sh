# #!/bin/bash

# # set variable for bucket-name
# BUCKET_NAME="eks-statefile-bucket1"
# AWS_REGION="eu-west-3"
# AWS_PROFILE="Lington"

# # sso login
# echo ">> Logging into AWS SSO..."
# aws sso logout >/dev/null 2>&1 || true
# aws sso login --profile "$AWS_PROFILE"

# export AWS_PROFILE=Lington
# export AWS_SDK_LOAD_CONFIG=1

# # create bucket
# aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" \
#   --create-bucket-configuration LocationConstraint="$AWS_REGION"

# # enable versioning
# aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" \
#   --versioning-configuration Status=Enabled

# echo "Creating Cluster"
# cd netwoking
# terraform init
# terraform fmt 
# terraform validate
# terraform apply -auto-approve











#!/bin/bash

# === Config ===
BUCKET_NAME="eks-statefile-bucket1"
AWS_REGION="eu-west-3"
AWS_PROFILE="Lington"
CLUSTER_NAME="staging-demo-eks"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# AWS SSO Login
echo ">> Logging into AWS SSO for profile: $AWS_PROFILE"
aws sso logout >/dev/null 2>&1 || true
aws sso login --profile "$AWS_PROFILE"

export AWS_PROFILE="$AWS_PROFILE"
export AWS_SDK_LOAD_CONFIG=1

# Create S3 bucket for Terraform state
echo ">> Creating S3 bucket for Terraform state: $BUCKET_NAME (region: $AWS_REGION)"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" \
  || echo "   -> Bucket may already exist, continuing..."

# enable versioning
echo ">> Enabling versioning on bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --versioning-configuration Status=Enabled

# Terraform: VPC + EKS cluster
echo ">> Running Terraform for networking + EKS..."
cd "$ROOT_DIR/netwoking"

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve

# Go back to repo root
cd "$ROOT_DIR"

# Configure kubectl for EKS cluster
echo ">> Updating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --profile "$AWS_PROFILE"

kubectl cluster-info

# Install metrics-server (required for HPA)
echo ">> Installing / updating metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo ">> Waiting for metrics-server rollout..."
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s || \
  echo "   -> metrics-server may still be starting, 'kubectl top' might need a bit more time."

# Apply Kubernetes objects: Namespaces, App, HPA, Autoscaler 
echo ">> Applying Namespaces..."
kubectl apply -f "$ROOT_DIR/k8s/namespace/"

echo ">> Deploying Nginx demo app + Service..."
kubectl apply -f "$ROOT_DIR/k8s/app/"

echo ">> Applying HPA..."
kubectl apply -f "$ROOT_DIR/k8s/hpa/"

echo ">> Applying Cluster Autoscaler (SA + RBAC + Deployment)..."
kubectl apply -f "$ROOT_DIR/k8s/autoscaler/cluster-autoscaler-sa.yaml"
kubectl apply -f "$ROOT_DIR/k8s/autoscaler/cluster-autoscaler-role.yaml"
kubectl apply -f "$ROOT_DIR/k8s/autoscaler/cluster-autoscaler-rolebinding.yaml"
kubectl apply -f "$ROOT_DIR/k8s/autoscaler/cluster-autoscaler.yaml"


echo "==============================================="
echo " All done! EKS + app + HPA + Cluster Autoscaler deployed."
echo "==============================================="


# # --- 7) Quick status checks ---
# echo ">> Checking pods in prod-frontend..."
# kubectl get pods -n prod-frontend -o wide

# echo ">> Checking service (ELB should appear)..."
# kubectl get svc -n prod-frontend

# echo ">> Checking HPA..."
# kubectl get hpa -n prod-frontend

# echo ">> Checking Cluster Autoscaler pod..."
# kubectl -n kube-system get pods -l app=cluster-autoscaler

# echo "==============================================="
# echo " All done! EKS + app + HPA + Cluster Autoscaler deployed."
# echo "==============================================="
