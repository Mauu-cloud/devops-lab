# Entorno de práctica SIN nube: usa Docker local como "proveedor".
# Mismo flujo que en AWS/Azure/GCP: init -> plan -> apply -> destroy
terraform {
  required_version = ">= 1.5"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # Backend local (state en un archivo). En un equipo real iría en S3 / Azure Storage / GCS.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {}

# Reutilizamos el MISMO módulo dos veces con distintos parámetros
module "app_dev" {
  source        = "../modules/docker-app"
  name          = "devops-lab-dev"
  image         = var.image
  external_port = 8081
  env           = { APP_VERSION = "dev" }
}

module "app_qa" {
  source        = "../modules/docker-app"
  name          = "devops-lab-qa"
  image         = var.image
  external_port = 8082
  env           = { APP_VERSION = "qa" }
}
