terraform {
  required_providers {
    oci = { source = "chainguard-dev/oci" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_exec_test" "version" {
  digest = var.digest
  script = "docker run --rm $IMAGE_NAME --version"
}


data "oci_string" "ref" {
  input = var.digest
}

resource "random_id" "hex" { byte_length = 4 }

resource "helm_release" "kube-prometheus-stack" {
  name       = "prometheus-${random_id.hex.hex}"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  namespace        = "prometheus-${random_id.hex.hex}"
  create_namespace = true

  // node-exporter
  set {
    name  = "prometheus-node-exporter.image.registry"
    value = data.oci_string.ref.registry
  }
  set {
    name  = "prometheus-node-exporter.image.repository"
    value = data.oci_string.ref.repo
  }
  set {
    name  = "prometheus-node-exporter.image.digest"
    value = data.oci_string.ref.digest
  }
}

data "oci_exec_test" "node-runs" {
  depends_on = [resource.helm_release.kube-prometheus-stack]

  digest      = var.digest
  script      = "./node-runs.sh ${random_id.hex.hex}"
  working_dir = path.module
}
