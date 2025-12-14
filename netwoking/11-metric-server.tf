# Deploy metric server using helm 
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  # # # Ensure Helm waits for resources to be ready (optional but nice)
  # wait    = true
  # timeout = 600

  # Important: make sure cluster exists before this runs
  depends_on = [
    module.eks_al2023
  ]

  values = [
    file("${path.module}/values/metrics-server.yaml")
  ]
  #   # Use YAML values instead of set {} blocks
  #   values = [<<EOF
  # args:
  #   - --kubelet-insecure-tls
  #   - --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
  # EOF
  #   ]
}