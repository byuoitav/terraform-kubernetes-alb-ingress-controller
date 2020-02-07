variable "k8s_cluster_name" {
  description = "Name of the Kubernetes cluster. This is used to construct AWS IAM policies/roles."
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy resources into"
  type        = string
  default     = "default"
}

variable "aws_iam_path_prefix" {
  description = "Prefix to be used for all AWS IAM objects."
  type        = string
  default     = ""
}

variable "aws_resource_name_prefix" {
  description = "A string to prefix any AWS resources created"
  type        = string
  default     = "k8s-"
}

variable "aws_tags" {
  description = "AWS tags to be applied to all AWS objects being created."
  type        = map(string)
  default     = {}
}

variable "external_dns_version" {
  description = "The version of ExternalDNS to use. See https://github.com/kubernetes-sigs/external-dns/releases for available versions"
  type        = string
  default     = "0.5.18"
}

variable "alb_ingress_controller_version" {
  description = "The version of ALB Ingress Controller to use. See https://github.com/kubernetes-sigs/aws-alb-ingress-controller/releases for available versions"
  type        = string
  default     = "1.1.5"
}
