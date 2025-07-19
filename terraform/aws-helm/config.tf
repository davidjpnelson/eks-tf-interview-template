
# Would I do this under any circumstances if I had more than 3 hours?  
## No
terraform {
  required_version = "1.12.0"
  # Really you ought to clean this up and use a remote backend, but this is an interview and I spin this up A LOT, then run aws-nuke on the account
  backend "local" {
    path = "test-interview-helm.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~>2.13"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Terraform = "true"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name =  var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", var.eks_cluster_name]
      command     = "aws"
    }
  }

  experiments {
    # manifest = true
  }
}
