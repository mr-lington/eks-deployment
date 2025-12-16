
# EFS + EFS CSI Driver (Pod Identity) + StorageClass


# EFS filesystem
resource "aws_efs_file_system" "eks" {
  creation_token   = "${module.eks_al2023.cluster_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = {
    Name        = "${module.eks_al2023.cluster_name}-efs"
    ManagedBy   = "Terraform"
    Environment = "staging"
  }
}

# Security Group for EFS (allow NFS 2049 from EKS nodes)
resource "aws_security_group" "efs" {
  name        = "${module.eks_al2023.cluster_name}-efs-sg"
  description = "Allow NFS from EKS nodes"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name      = "${module.eks_al2023.cluster_name}-efs-sg"
    ManagedBy = "Terraform"
  }
}

# Allow NFS from node SG -> EFS
resource "aws_security_group_rule" "efs_ingress_nfs_from_nodes" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = module.eks_al2023.node_security_group_id
}

# EFS egress
resource "aws_security_group_rule" "efs_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# EFS Mount Targets (private subnets)
resource "aws_efs_mount_target" "zone_a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = aws_subnet.private1.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "zone_b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = aws_subnet.private2.id
  security_groups = [aws_security_group.efs.id]
}

# IAM Role for EFS CSI via Pod Identity
data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
  }
}

resource "aws_iam_role" "efs_csi_driver" {
  name               = "${module.eks_al2023.cluster_name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}

# Pod Identity association (service account -> IAM role)
resource "aws_eks_pod_identity_association" "efs_csi_driver" {
  cluster_name    = module.eks_al2023.cluster_name
  namespace       = "kube-system"
  service_account = "efs-csi-controller-sa"
  role_arn        = aws_iam_role.efs_csi_driver.arn
}

# EFS CSI Driver Addon
resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name = module.eks_al2023.cluster_name
  addon_name   = "aws-efs-csi-driver"

  # Optional: pin version if you want, otherwise let AWS select compatible one, here we let aws handle that
  # addon_version = "vX.Y.Z-eksbuild.N"

  depends_on = [
    module.eks_al2023,
    aws_eks_pod_identity_association.efs_csi_driver,
    aws_efs_mount_target.zone_a,
    aws_efs_mount_target.zone_b,
  ]
}

# Kubernetes StorageClass for EFS (dynamic provisioning via Access Points)
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.eks.id
    directoryPerms   = "700"
  }

  mount_options = ["iam"]

  depends_on = [aws_eks_addon.efs_csi_driver]
}
