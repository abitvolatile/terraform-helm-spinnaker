# Input Variables

variable "google_project_name" {
  description = "Google Project Name. Must be less than 30 alpha-numberic characters. (Example: tf-gcp-test-project)"
}

variable "k8s_cluster_endpoint" {
  description = "Google Kubernetes Engine Cluster Endpoint"
}

variable "k8s_cluster_ca_certificate" {
  description = "Google Kubernetes Engine CA Certificate"
}

variable "k8s_nodepool_name" {
  description = "Google Kubernetes Engine Node Pool Name"
}

variable "k8s_access_token" {
  description = "Kubernetes Auth Token"
}

variable "helm_chart_version" {
  description = "Helm Chart Version"
}
