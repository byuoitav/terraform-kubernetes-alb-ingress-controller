locals {
  aws_iam_path_prefix         = var.aws_iam_path_prefix == "" ? null : var.aws_iam_path_prefix
  external_dns_name           = "external-dns"
  alb_ingress_controller_name = "alb-ingress-controller"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "selected" {
  name = var.k8s_cluster_name
}

data "aws_iam_policy_document" "eks_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.selected.identity.0.oidc.0.issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.k8s_namespace}:${local.alb_ingress_controller_name}",
        "system:serviceaccount:${var.k8s_namespace}:${local.external_dns_name}"
      ]
    }

    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.selected.identity.0.oidc.0.issuer, "https://", "")}"
      ]
      type = "Federated"
    }
  }
}
