#Helm installs
resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.4.3"

  # MUST be set if you want sync to Kubernetes Secret
  set {
    name  = "syncSecret.enabled"
    value = true
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


# ServiceAccount (Pod Identity uses this SA)
resource "kubernetes_service_account_v1" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "prod-frontend"
  }

  depends_on = [helm_release.secrets_csi_driver_aws_provider]
}


# IAM trust policy for Pod Identity
data "aws_iam_policy_document" "myapp_secrets_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}


# IAM Role + permissions (Secrets Manager)
resource "aws_iam_role" "myapp_secrets" {
  name               = "${module.eks_al2023.cluster_name}-myapp-secrets"
  assume_role_policy = data.aws_iam_policy_document.myapp_secrets_assume.json
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
        Resource = "arn:aws:secretsmanager:eu-west-3:468887949677:secret:database-*" # later replace with your specific secret ARN(s)
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myapp_secrets" {
  policy_arn = aws_iam_policy.myapp_secrets.arn
  role       = aws_iam_role.myapp_secrets.name
}


# Pod Identity association (SA -> Role)
resource "aws_eks_pod_identity_association" "myapp_secrets" {
  cluster_name    = module.eks_al2023.cluster_name
  namespace       = "prod-frontend"
  service_account = "myapp"
  role_arn        = aws_iam_role.myapp_secrets.arn

  depends_on = [
    module.eks_al2023,
    kubernetes_service_account_v1.myapp
  ]
}

output "myapp_secrets_role_arn" {
  value = aws_iam_role.myapp_secrets.arn
}
