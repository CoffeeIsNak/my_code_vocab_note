# root/main.tf
provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "eks-vpc"
  cidr = "172.31.0.0/16"
  azs  = ["ap-northeast-2a", "ap-northeast-2c"]

  public_subnets = ["172.31.0.0/20", "172.31.16.0/20"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "eks-vpc"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "my-eks"
  cluster_version = "1.30"
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
  }

  eks_managed_node_groups = {
    default = {
      name = "my-node-group"
    }
  }

  tags = {
    Environment = "dev"
    Project     = "code-parser"
  }
}

module "alb_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.30.0"

  create_role                   = true
  role_name                     = "eks-alb-controller"
  provider_url                  = module.eks.oidc_provider
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]

  tags = {
    Name = "alb-irsa"
  }
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set { name = "clusterName", value = module.eks.cluster_name }
  set { name = "serviceAccount.create", value = "false" }
  set { name = "serviceAccount.name", value = "aws-load-balancer-controller" }
  set { name = "region", value = "ap-northeast-2" }
  set { name = "vpcId", value = module.vpc.vpc_id }
  set { name = "image.tag", value = "v2.6.1" }
}

resource "kubernetes_service_account" "alb" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.alb_irsa.iam_role_arn
    }
  }

  automount_service_account_token = true
}
