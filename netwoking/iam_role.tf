# data "aws_caller_identity" "current" {}

# data "aws_iam_policy_document" "assume_humans" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }
#   }
# }

# resource "aws_iam_role" "devops_admin" {
#   name               = "DevOpsAdminRole"
#   assume_role_policy = data.aws_iam_policy_document.assume_humans.json
# }

# resource "aws_iam_role" "developer" {
#   name               = "DeveloperRole"
#   assume_role_policy = data.aws_iam_policy_document.assume_humans.json
# }

# resource "aws_iam_role" "support" {
#   name               = "SupportReadOnlyRole"
#   assume_role_policy = data.aws_iam_policy_document.assume_humans.json
# }

# resource "aws_iam_role" "cicd" {
#   name               = "CICDRole"
#   assume_role_policy = data.aws_iam_policy_document.assume_humans.json
# }
