// https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "selected" {
  name = var.k8s_cluster_name
}

data "aws_region" "current" {
  name = var.aws_region_name
}

data "aws_iam_policy_document" "eks_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.selected[0].identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.k8s_namespace}:external-dns",
        "system:serviceaccount:${var.k8s_namespace}:alb-ingress-controller"
      ]
    }

    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.selected[0].identity[0].oidc[0].issuer, "https://", "")}"
      ]
      type = "Federated"
    }
  }
}
