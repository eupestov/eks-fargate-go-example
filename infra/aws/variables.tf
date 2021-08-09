variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "devops"
}

variable "stage" {
  type        = string
  description = "Stage name, e.g. dev, uat, prod"
  default     = "dev"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to use"
  default     = 3
}

variable "vpc_cidr" {
  type        = string
  description = "Primary VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "namespaces" {
  type        = list(string)
  description = "K8s namespaces for Frargate profiles"
  default     = ["kube-system", "application"]
}

variable "alb_ingress_controller_service_account" {
  type        = string
  description = "Kubernetes servie account of ALB ingress controller"
  default     = "alb-ingress-controller"
}
