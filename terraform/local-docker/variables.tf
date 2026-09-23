variable "image" {
  description = "Imagen construida localmente con: docker build -t devops-lab:local ."
  type        = string
  default     = "devops-lab:local"
}
