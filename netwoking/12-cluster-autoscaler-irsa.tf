# iam role when using pod identity agent
# IAM role for Cluster Autoscaler (EKS Pod Identity)
resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_policy" "cluster_autoscaler" {
  name = "cluster-autoscaler"
  #   description = "Cluster Autoscaler permissions for EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# Pod Identity association for Cluster Autoscaler
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = module.eks_al2023.cluster_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}


# Deploy CA using helm
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  # Optional but recommended
  wait    = true
  timeout = 300

  values = [<<EOF
rbac:
  serviceAccount:
    create: true
    name: cluster-autoscaler

autoDiscovery:
  clusterName: ${module.eks_al2023.cluster_name}

awsRegion: eu-west-3
cloudProvider: aws

extraArgs:
  balance-similar-node-groups: "true"
  skip-nodes-with-system-pods: "false"
  skip-nodes-with-local-storage: "false"
  node-group-auto-discovery: "asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${module.eks_al2023.cluster_name}"
EOF
  ]

  depends_on = [
    helm_release.metrics_server
  ]
}
