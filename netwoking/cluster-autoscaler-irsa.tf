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

# Deploy metric server using helm 
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  # # Ensure Helm waits for resources to be ready (optional but nice)
  wait    = true
  timeout = 300

  # Important: make sure cluster exists before this runs
  depends_on = [
    module.eks_al2023
  ]

  # Use YAML values instead of set {} blocks
  values = [<<EOF
args:
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
EOF
  ]
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
    module.eks_al2023,
    helm_release.metrics_server,
    aws_eks_pod_identity_association.cluster_autoscaler,
  ]
}




# # iam role when using openID connect
# # you need to apply the files in autoscaler(which are sa, cluster-role and clusterRoleBinding)

# resource "aws_iam_role" "cluster_autoscaler" {
#   name = "ClusterAutoscalerRole-${module.eks_al2023.cluster_name}"
#   #assume_role_policy = file("${path.module}/../k8s/autoscaler/trust-policy.json")
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::468887949677:oidc-provider/oidc.eks.eu-west-3.amazonaws.com/id/6966BFFBE14B8710673B2C2D7885CE00"
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "oidc.eks.eu-west-3.amazonaws.com/id/6966BFFBE14B8710673B2C2D7885CE00:aud" = "sts.amazonaws.com"
#             "oidc.eks.eu-west-3.amazonaws.com/id/6966BFFBE14B8710673B2C2D7885CE00:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
#           }
#         }
#       }
#     ]
#   })

# }

# resource "aws_iam_policy" "cluster_autoscaler" {
#   name = "ClusterAutoscalerPolicy-${module.eks_al2023.cluster_name}"
#   #policy = file("${path.module}/../k8s/autoscaler/ClusterAutoscalerPolicy.json")
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "autoscaling:DescribeAutoScalingGroups",
#           "autoscaling:DescribeAutoScalingInstances",
#           "autoscaling:DescribeLaunchConfigurations",
#           "autoscaling:DescribeTags",
#           "ec2:DescribeImages",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeLaunchTemplateVersions",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeInstanceTypeOfferings"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "autoscaling:SetDesiredCapacity",
#           "autoscaling:TerminateInstanceInAutoScalingGroup"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             #"aws:ResourceTag/kubernetes.io/cluster/staging-demo-eks" = "owned"
#             "aws:ResourceTag/kubernetes.io/cluster/${module.eks_al2023.cluster_name}" = "owned"
#           }
#         }
#       }
#     ]
#   })

# }

# resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
#   role       = aws_iam_role.cluster_autoscaler.name
#   policy_arn = aws_iam_policy.cluster_autoscaler.arn
# }