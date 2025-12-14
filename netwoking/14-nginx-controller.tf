resource "helm_release" "external_nginx" {
  name             = "external"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true

  # Use a newer stable chart version
  version = "4.14.1"

  values = [
    file("${path.module}/values/nginx-ingress.yaml")
  ]

  depends_on = [
    helm_release.aws_lbc
  ]
}
