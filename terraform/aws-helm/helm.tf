locals {
    namespaces = {
        "aws-load-balancer-controller" = "aws-load-balancer-controller"
        "external-dns" = "external-dns"
        "cluster-autoscaler" = "cluster-autoscaler"
        "metrics-server" = "kube-system"
    }

    service_accounts = {
        "aws-load-balancer-controller" = "aws-load-balancer-controller"
        "external-dns" = "external-dns"
        "cluster-autoscaler" = "cluster-autoscaler"
    }

    irsa_roles = {
        "aws-load-balancer-controller" = module.aws-load-balancer-irsa.iam_role_arn
        "external-dns" =  module.external-dns-irsa.iam_role_arn
        "cluster-autoscaler" = module.aws-cluster-autoscaler-irsa.iam_role_arn
    }
    
}

data "aws_ssm_parameter" "oidc_provider" {
  name = "/eks/${var.eks_cluster_name}/oidc_provider"
}

resource "kubernetes_namespace" "namespaces" {
    for_each = {for namespace, value in local.namespaces: namespace => value if value != "kube-system" }
    metadata {
        name = each.value
    }
}

resource "kubernetes_service_account" "service_accounts" {
    for_each = local.service_accounts
    metadata {
        name      = each.value
        namespace = local.namespaces[each.key]
        annotations = {
          "eks.amazonaws.com/role-arn" = local.irsa_roles[each.key]
        }
    }
    depends_on = [ kubernetes_namespace.namespaces ]
}

resource "aws_iam_policy" "aws-load-balancer-controller" {
    name = "aws-load-balancer-controller-${var.eks_cluster_name}-policy"
    path = "/"
    policy = file("${path.module}/assets/aws-lb-controller-iam-policy.json")
}


module "aws-load-balancer-irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = data.aws_ssm_parameter.oidc_provider.value
      namespace_service_accounts = ["${local.namespaces.aws-load-balancer-controller}:${local.service_accounts.aws-load-balancer-controller}"]
    }
  }
  role_name = "aws-load-balancer-controller-${var.eks_cluster_name}-role"
}

module "external-dns-irsa" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
    attach_external_dns_policy = true
    
    oidc_providers = {
        main = {
        provider_arn               = data.aws_ssm_parameter.oidc_provider.value
        namespace_service_accounts = ["${local.namespaces.external-dns}:${local.service_accounts.external-dns}"]
        }
    }
    role_name = "external-dns-${var.eks_cluster_name}-role"
}

module "aws-cluster-autoscaler-irsa" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

    attach_cluster_autoscaler_policy = true
    cluster_autoscaler_cluster_names = [var.eks_cluster_name]

    oidc_providers = {
        main = {
            provider_arn               = data.aws_ssm_parameter.oidc_provider.value
            namespace_service_accounts = ["${local.namespaces.cluster-autoscaler}:${local.service_accounts.cluster-autoscaler}"]
        }
    }
    role_name = "aws-cluster-autoscaler-${var.eks_cluster_name}-role"
}

resource "helm_release" "aws-load-balancer-controller" {
    name       = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"
    namespace  = local.namespaces["aws-load-balancer-controller"]
    version    = "1.5.3"
    
    wait = true
    
    set {
        name  = "clusterName"
        value = var.eks_cluster_name
    }

    set {
        name  = "serviceAccount.create"
        value = "false"
    }

    set {
        name  = "serviceAccount.name"
        value = local.service_accounts.aws-load-balancer-controller
    }
    depends_on = [ kubernetes_service_account.service_accounts ]
}

resource "helm_release" "external-dns" {
    name = "external-dns"
    repository = "https://charts.bitnami.com/bitnami"
    chart = "external-dns"
    namespace = local.namespaces["external-dns"]
    version = "6.20.3"

    wait = true

    set {
        name = "serviceAccount.create"
        value = "false"
    }

    set {
        name = "serviceAccount.name"
        value = local.service_accounts.external-dns
    }

    depends_on = [ kubernetes_service_account.service_accounts ]
}

resource "helm_release" "cluster-autoscaler" {
    name = "cluster-autoscaler"
    repository = "https://kubernetes.github.io/autoscaler"
    chart = "cluster-autoscaler"
    namespace = local.namespaces["cluster-autoscaler"]
    version = "9.37.0"

    wait = true

    set {
        name = "autoDiscovery.clusterName"
        value = var.eks_cluster_name
    }

    set {
        name = "awsRegion"
        value = var.aws_region
    }

    set {
        name = "rbac.serviceAccount.create"
        value = "false"
    }

    set {
        name = "rbac.serviceAccount.name"
        value = local.service_accounts.cluster-autoscaler
    }
    depends_on = [ kubernetes_service_account.service_accounts ]
}

resource "helm_release" "metrics-server" {
    name = "metrics-server"
    repository = "https://kubernetes-sigs.github.io/metrics-server"
    chart = "metrics-server"
    namespace = local.namespaces["metrics-server"]
    version = "3.12.2"

    wait = true
    # If you don't have a namespace named kube-system yet, what are we even doing here kids?
    create_namespace = false

}


