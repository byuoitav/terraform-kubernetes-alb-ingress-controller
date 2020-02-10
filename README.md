# terraform-kubernetes-alb-ingress-controller
Terraform module to deploy AWS ALB Ingress Controller and External DNS. 

Requires an [OpenID connect provider](https://www.terraform.io/docs/providers/aws/r/iam_openid_connect_provider.html) for your EKS cluster to already be created. You can find an example of how to create one [here](https://www.terraform.io/docs/providers/aws/r/eks_cluster.html#enabling-iam-roles-for-service-accounts)
