# Docker Hub 向けのプルスルーキャッシュ (remote repository)。
# 公開 Docker Hub イメージは Cloud Run から直接利用できるが、
# キャッシュと可用性のため Artifact Registry remote repository を経由して取得する。
resource "google_artifact_registry_repository" "docker_hub" {
  project       = var.PROJECT_ID
  location      = local.location
  repository_id = "docker-hub-remote"
  description   = "Pull-through cache for Docker Hub (docker.io), used by Cloud Run services"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  remote_repository_config {
    description = "Docker Hub remote repository"
    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }

  depends_on = [
    google_project_service.service
  ]
}
