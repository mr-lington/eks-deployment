# # DevOps admin - cluster admin permission
# resource "aws_eks_access_entry" "devops_admin" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.devops_admin.arn
#   type          = "STANDARD"

# }

# resource "aws_eks_access_policy_association" "devops_admin" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.devops_admin.arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   access_scope { type = "cluster" }
# }

# # Developer - namespace view (RBAC grants write)
# resource "aws_eks_access_entry" "developer" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.developer.arn
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "developer" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.developer.arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#   access_scope {
#     type       = "namespace"
#     namespaces = ["prod-backend", "prod-frontend", "prod-data"]
#   }
# }

# # Support - read only cluster-wide
# resource "aws_eks_access_entry" "support" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.support.arn
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "support" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.support.arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#   access_scope { type = "cluster" }
# }

# # CI/CD limited namespaces
# resource "aws_eks_access_entry" "cicd" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.cicd.arn
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "cicd" {
#   cluster_name  = module.eks_al2023.cluster_name
#   principal_arn = aws_iam_role.cicd.arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#   access_scope {
#     type       = "namespace"
#     namespaces = ["prod-backend", "prod-frontend"]
#   }
# }

