# resource "aws_iam_role" "eks" {
#   name = "${local.env}-${local.eks_name}-eks-cluster"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "eks.amazonaws.com"
#       }
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "eks" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks.name
# }

# resource "aws_eks_cluster" "eks" {
#   name     = "${local.env}-${local.eks_name}"
#   version  = local.eks_version
#   role_arn = aws_iam_role.eks.arn

#   vpc_config {
#     endpoint_private_access = false
#     endpoint_public_access  = true

#     subnet_ids = [
#       aws_subnet.private1.id,
#       aws_subnet.private2.id,
#       aws_subnet.private3.id
#     ]
#   }

#   access_config {
#     authentication_mode                         = "API"
#     bootstrap_cluster_creator_admin_permissions = true
#   }

#   depends_on = [aws_iam_role_policy_attachment.eks]
# }



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

      min_size = 1
      max_size = 5
      desired_size = 1

    }
  }

  endpoint_public_access  = true
  endpoint_private_access = false
  
}


# EKS Access Entry for IAM User (lington)
resource "aws_eks_access_entry" "lington" {
  cluster_name  = module.eks_al2023.cluster_name
  principal_arn = "arn:aws:iam::468887949677:user/lington"
  type          = "STANDARD"

  depends_on = [module.eks_al2023]
}


# Associate AmazonEKSClusterAdminPolicy with the user
resource "aws_eks_access_policy_association" "lington_admin" {
  cluster_name  = module.eks_al2023.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.lington.principal_arn

  access_scope {
    type = "cluster"
  }
}
