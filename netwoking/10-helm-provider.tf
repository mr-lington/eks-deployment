# Use the EKS module outputs instead of a non-existent aws_eks_cluster resource
data "aws_eks_cluster" "eks" {
  name = module.eks_al2023.cluster_name

  # makes sure the cluster exists before this data source is read
  depends_on = [module.eks_al2023]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks_al2023.cluster_name

  depends_on = [module.eks_al2023]
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}


# data "aws_eks_cluster" "eks" {
#   name       = module.eks_al2023.cluster_name
#   depends_on = [module.eks_al2023]
# }

# data "aws_eks_cluster_auth" "eks" {
#   name       = module.eks_al2023.cluster_name
#   depends_on = [module.eks_al2023]
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }
