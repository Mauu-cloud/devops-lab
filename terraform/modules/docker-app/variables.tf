variable "name" {
  description = "Nombre del contenedor"
  type        = string
}

variable "image" {
  description = "Imagen a desplegar (ej: devops-lab:local)"
  type        = string
}

variable "internal_port" {
  type    = number
  default = 8080
}

variable "external_port" {
  type = number
}

variable "env" {
  description = "Variables de entorno"
  type        = map(string)
  default     = {}
}
