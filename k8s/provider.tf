data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "eks-statefile-bucket1"
    key    = "clusterdeploy/terraform.tfstate"
    region = "eu-west-3"
    profile      = "Lington"
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "Lington"
}

data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.infra.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca)
  token                  = data.aws_eks_cluster_auth.eks.token
}
