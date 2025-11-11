
# EKS terraform module
module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.env}-demo-eks"
  kubernetes_version = "1.33"

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
    aws_subnet.private2.id,
    aws_subnet.private3.id
  ]

  eks_managed_node_groups = {
    demo-NG = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["t3.medium"]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = 1
      max_size     = 5
      desired_size = 1

    }
  }

  endpoint_public_access  = true
  endpoint_private_access = false

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