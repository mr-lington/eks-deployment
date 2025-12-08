
# EKS terraform module
module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.env}-demo-eks"
  kubernetes_version = "1.33"


  # Optional
  endpoint_public_access = true # This is needed to reach the kubernetes API from public access, that is accessinng kubectl from your laptop

  # EKS Addons
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
    #aws_subnet.private3.id
  ]


  eks_managed_node_groups = {
    demo-NG = {
      instance_types = ["t3.medium"] # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 5
      desired_size   = 1

      tags = {
        "k8s.io/cluster-autoscaler/enabled"                           = "true"
        "k8s.io/cluster-autoscaler/${module.eks_al2023.cluster_name}" = "true"
      }
    }
  }

  tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}


# aws configure sso
# aws sso logout || true
# aws sso login --profile Lington
# aws eks update-kubeconfig --name staging-demo-eks --region eu-west-3 --profile Lington
# aws eks update-kubeconfig --region eu-west-3 --name staging-demo-eks --profile support-sso
# aws eks update-kubeconfig --region eu-west-3 --name staging-demo-eks --profile developer-sso
# kubectl get nodes
# ~/.aws/config      to check SSO credential that is created temporarily
# aws sts get-caller-identity --profile support-sso
# aws sts get-caller-identity --profile developer-sso


# steps to install metric server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# kubectl get deployment metrics-server -n kube-system
# kubectl top nodes


# order to apply the autoscaler