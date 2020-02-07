resource "aws_iam_role" "alb_ingress_controller" {
  name                  = "${var.aws_resource_name_prefix}${var.k8s_cluster_name}-${local.alb_ingress_controller_name}"
  description           = "Permissions required by the Kubernetes AWS ALB Ingress Controller pod."
  path                  = var.aws_iam_path_prefix
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.eks_oidc_assume_role.json
  tags                  = var.aws_tags
}

data "aws_iam_policy_document" "alb_ingress_controller" {
  statement {
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebACL",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cognito-idp:DescribeUserPoolClient"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "tag:GetResources",
      "tag:TagResources",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "waf:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb_ingress_controller" {
  name        = "${var.aws_resource_name_prefix}${var.k8s_cluster_name}-${local.alb_ingress_controller_name}"
  description = "Permissions that are required to manage AWS Application Load Balancers."
  path        = var.aws_iam_path_prefix
  policy      = data.aws_iam_policy_document.alb_ingress_controller.json
}

resource "aws_iam_role_policy_attachment" "alb_ingress_controller" {
  policy_arn = aws_iam_policy.alb_ingress_controller.arn
  role       = aws_iam_role.alb_ingress_controller.name
}

resource "kubernetes_service_account" "alb_ingress_controller" {
  metadata {
    name      = local.alb_ingress_controller_name
    namespace = var.k8s_namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_ingress_controller.arn
    }

    labels = {
      "app.kubernetes.io/name"       = local.alb_ingress_controller_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "alb_ingress_controller" {
  metadata {
    name = local.alb_ingress_controller_name

    labels = {
      "app.kubernetes.io/name"       = local.alb_ingress_controller_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = ["", "extensions"]
    resources = [
      "configmaps",
      "endpoints",
      "events",
      "ingresses",
      "ingresses/status",
      "services"
    ]
    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch",
      "patch"
    ]
  }

  rule {
    api_groups = ["", "extensions"]
    resources = [
      "nodes",
      "pods",
      "secrets",
      "services",
      "namespaces",
    ]
    verbs = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "alb_ingress_controller" {
  metadata {
    name = local.alb_ingress_controller_name

    labels = {
      "app.kubernetes.io/name"       = local.alb_ingress_controller_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.alb_ingress_controller.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.alb_ingress_controller.metadata.0.name
    namespace = kubernetes_service_account.alb_ingress_controller.metadata.0.namespace
  }
}

resource "kubernetes_deployment" "alb_ingress_controller" {
  depends_on = [kubernetes_cluster_role_binding.alb_ingress_controller]

  metadata {
    name      = local.alb_ingress_controller_name
    namespace = var.k8s_namespace

    labels = {
      "app.kubernetes.io/name"       = local.alb_ingress_controller_name
      "app.kubernetes.io/version"    = "v${var.alb_ingress_controller_version}"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = local.alb_ingress_controller_name
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = local.alb_ingress_controller_name
          "app.kubernetes.io/version" = "v${var.alb_ingress_controller_version}"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.alb_ingress_controller.metadata.0.name
        // dns_policy           = "ClusterFirst"
        // restart_policy       = "Always"

        container {
          name              = "server"
          image             = "docker.io/amazon/aws-alb-ingress-controller:v${var.alb_ingress_controller_version}"
          image_pull_policy = "Always"
          // termination_message_path = "/dev/termination-log"

          args = [
            "--ingress-class=alb",
            "--cluster-name=${var.k8s_cluster_name}",
            "--aws-vpc-id=${data.aws_eks_cluster.selected.0.vpc_config.0.vpc_id}",
            "--aws-region=${data.aws_region.current.name}",
            "--aws-max-retries=10",
          ]

          //volume_mount {
          //  mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
          //  name       = kubernetes_service_account.this.default_secret_name
          //  read_only  = true
          //}

          port {
            name           = "health"
            container_port = 10254
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              scheme = "HTTP"
              port   = "health"
              path   = "/healthz"
            }

            initial_delay_seconds = 30
            period_seconds        = 60
            timeout_seconds       = 3
          }

          liveness_probe {
            http_get {
              scheme = "HTTP"
              port   = "health"
              path   = "/healthz"
            }

            initial_delay_seconds = 60
            period_seconds        = 60
            timeout_seconds       = 3
          }
        }

        //volume {
        //  name = kubernetes_service_account.this.default_secret_name

        //  secret {
        //    secret_name = kubernetes_service_account.this.default_secret_name
        //  }
        //}
      }
    }
  }
}
