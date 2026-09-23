variable "region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  description = "Formato OWNER/REPO, ej: mauricio/devops-lab"
  type        = string
}
