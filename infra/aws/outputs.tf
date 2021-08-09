output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_id
}

output "alb_role_arn" {
  value       = aws_iam_role.alb-ingress-controller.arn
  description = "The role to be attached to alb-ingress-contoller service account"
}
