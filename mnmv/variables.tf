variable "project_dir" {
  description = "Diretório do projeto do usuário (contém cloud.yaml e apps/). O script `mnmv` passa o diretório atual."
  type        = string
}

variable "kubeconfig" {
  description = "Caminho do kubeconfig do k3s."
  type        = string
}

variable "registry" {
  description = "Registry local onde as imagens buildadas são publicadas."
  type        = string
  default     = "localhost:5000"
}

variable "namespace" {
  description = "Namespace onde os apps são criados."
  type        = string
  default     = "mnmv"
}
