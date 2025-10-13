provider "aws" {
  region  = local.region
  profile = "Lington"
}  


terraform {
  backend "s3" {
    bucket       = "eks-statefile-bucket1"
    use_lockfile = true
    key          = "cluster/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    profile      = "Lington"
  }
}