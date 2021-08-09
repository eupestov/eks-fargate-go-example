provider "aws" {
  region     = var.aws_region
}

terraform {
  required_version = "~> 0.15.3"
}

# Consistent resource naming and tagging
module "label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  environment = var.environment
  stage       = var.stage
  name        = "example"
}

# Fetch context information
data "aws_caller_identity" "current" {}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

locals {

  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Automated cidr creation using the idea from: https://aws.amazon.com/blogs/startups/practical-vpc-design/
  az_bits = ceil(log(var.az_count, 2))
  az_cidr_list = [
    for az in local.availability_zones :
    cidrsubnet(var.vpc_cidr, local.az_bits, index(local.availability_zones, az))
  ]
  private_subnets = [
    for az_cidr in local.az_cidr_list : cidrsubnet(az_cidr, 1, 0)
  ]
  public_subnets = [
    for az_cidr in local.az_cidr_list : cidrsubnet(cidrsubnet(az_cidr, 1, 1), 1, 0)
  ]

  cluster_name = format("%s-eks", module.label.id)
}

## Network
#
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = format("%s-vpc", module.label.id)
  cidr                 = var.vpc_cidr
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets      = local.private_subnets
  public_subnets       = local.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = module.label.tags

  # Tags required for cloud manager auto-discovery
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

## EKS cluster
#
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  manage_aws_auth  = false
  enable_irsa      = true
  write_kubeconfig = false

  tags = module.label.tags
}

## IAM configuration
#
resource "aws_iam_role" "fargate" {
  name = format("%s-fg-profile", module.label.id)

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

resource "aws_iam_role" "alb-ingress-controller" {
  name = format("%s-alb", module.label.id)

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:${var.alb_ingress_controller_service_account}"
        }
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_policy" "alb-ingress-controller" {
  name   = "ALBIngressControllerIAMPolicy"
  policy = file("${path.module}/files/alb-ingress-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb-ALBIngressControllerIAMPolicy" {
  policy_arn = aws_iam_policy.alb-ingress-controller.arn
  role       = aws_iam_role.alb-ingress-controller.name
}

## Fargate profile
#
resource "aws_eks_fargate_profile" "fargate-profile" {
  cluster_name           = module.eks.cluster_id
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = module.vpc.private_subnets

  dynamic "selector" {
    for_each  = toset(var.namespaces)
    content {
      namespace = selector.key
    }
  }

  tags = module.label.tags
}
