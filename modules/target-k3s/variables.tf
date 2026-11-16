variable "name" {
  type = string
}

variable "app" {
  description = "Spec do app (apps/<nome>.yaml). Só `build` é obrigatório na POC."
  type = object({
    build    = string
    port     = optional(number) # padrão: EXPOSE do Dockerfile, senão 80
    replicas = optional(number, 1)
    public   = optional(bool, true)
    size     = optional(string, "small")
    env      = optional(map(string), {})
  })

  validation {
    condition     = contains(["small", "medium", "large"], var.app.size)
    error_message = "size deve ser small, medium ou large."
  }
}

variable "base_dir" {
  description = "Diretório do arquivo do app; `build` é relativo a ele."
  type        = string
}

variable "domain" {
  type = string
}

variable "namespace" {
  type = string
}

variable "registry" {
  type = string
}
