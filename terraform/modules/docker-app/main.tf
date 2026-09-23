# MÓDULO reutilizable: despliega una app en un contenedor Docker.
# Un módulo es a Terraform lo que una función es a Python: entrada (variables) -> recursos -> salida (outputs)
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_container" "this" {
  name  = var.name
  image = var.image

  ports {
    internal = var.internal_port
    external = var.external_port
  }

  env = [for k, v in var.env : "${k}=${v}"]

  restart = "unless-stopped"
}
