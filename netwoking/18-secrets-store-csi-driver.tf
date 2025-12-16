
data "tls_certificate" "eks" {
  url = module.eks_al2023.cluster_oidc_issuer_url
}

data "aws_iam_openid_connect_provider" "eks" {
  url = module.eks_al2023.cluster_oidc_issuer_url
}

resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.4.3"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
}

resource "helm_release" "secrets_csi_driver_aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "0.3.9"

  depends_on = [helm_release.secrets_csi_driver]
}


data "aws_iam_policy_document" "myapp_secrets" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_al2023.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:prod-frontend:myapp"
      ]
    }
  }
}


resource "aws_iam_role" "myapp_secrets" {
  name               = "${module.eks_al2023.cluster_name}-myapp-secrets"
  assume_role_policy = data.aws_iam_policy_document.myapp_secrets.json
}

resource "aws_iam_policy" "myapp_secrets" {
  name = "${module.eks_al2023.cluster_name}-myapp-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myapp_secrets" {
  role       = aws_iam_role.myapp_secrets.name
  policy_arn = aws_iam_policy.myapp_secrets.arn
}

output "myapp_secrets_role_arn" {
  value = aws_iam_role.myapp_secrets.arn
}


