### Terraform Resources

# Required Google Cloud Resources
resource "google_service_account" "spinnaker" {
  account_id = "spinnaker"
}

resource "google_service_account_key" "spinnaker" {
  service_account_id = google_service_account.spinnaker.name
}

resource "google_project_iam_member" "spinnaker-service-account-storage-admin" {
  role   = "roles/editor" # Could likely tighten this up a bit
  member = "serviceAccount:${google_service_account.spinnaker.email}"
}






# Kubernetes Resources

provider "kubernetes" {
  version = "1.11.2"

  load_config_file       = false
  host                   = "https://${var.k8s_cluster_endpoint}"
  token                  = var.k8s_access_token
  cluster_ca_certificate = var.k8s_cluster_ca_certificate
}


resource "kubernetes_namespace" "spinnaker" {
  metadata {
    name = "spinnaker"

    annotations = {
      nodepool_name = var.k8s_nodepool_name
    }
  }
}


resource "kubernetes_secret" "spinnaker-credentials" {
  metadata {
    name      = "spinnaker-credentials"
    namespace = kubernetes_namespace.spinnaker.metadata.0.name
  }

  data = {
    "key.json" = "${base64decode(google_service_account_key.spinnaker.private_key)}"
  }
}



# Helm Resources

provider "helm" {
  version = "1.2.1"

  kubernetes {
    load_config_file       = false
    host                   = "https://${var.k8s_cluster_endpoint}"
    token                  = var.k8s_access_token
    cluster_ca_certificate = var.k8s_cluster_ca_certificate
  }
}


resource "helm_release" "spinnaker" {
  name      = "spinnaker"
  chart     = "${path.module}/helm/spinnaker"
  namespace = "spinnaker"
  version   = var.helm_chart_version

  create_namespace  = true
  dependency_update = true
  recreate_pods     = true
  force_update      = true
  atomic            = true
  cleanup_on_fail   = false
  wait              = true
  timeout           = "1200" # 20mins

  set {
    name  = "cluster.nodepool.name"
    value = var.k8s_nodepool_name
  }

  set {
    name  = "gcs.enabled"
    value = true
  }

  set {
    name  = "gcs.project"
    value = var.google_project_name
  }

  set {
    name  = "gcs.bucket"
    value = "spinnaker-${var.google_project_name}"
  }

  set {
    name  = "gcs.jsonKey"
    value = ""
  }

  set {
    name  = "gcs.secretName"
    value = kubernetes_secret.spinnaker-credentials.metadata.0.name
  }

  values = [
    "${file("${path.module}/spinnaker-values.yaml")}"
  ]
}
