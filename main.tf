locals {
  # O código do MNMV vem do GitHub; o projeto do usuário (cloud.yaml + apps/) fica em project_dir.
  project = abspath(var.project_dir)
  cloud   = yamldecode(file("${local.project}/cloud.yaml"))

  provider = try(local.cloud.provider, "k3s")
  domain   = try(local.cloud.domain, "localhost")

  # Convenção: cada arquivo em apps/ é um app; o nome do app é o nome do arquivo.
  apps = {
    for f in fileset("${local.project}/apps", "*.{yaml,yml}") :
    trimsuffix(trimsuffix(f, ".yaml"), ".yml") => yamldecode(file("${local.project}/apps/${f}"))
  }
}

resource "kubernetes_namespace_v1" "mnmv" {
  count = local.provider == "k3s" ? 1 : 0
  metadata { name = var.namespace }
}

module "k3s" {
  source   = "./modules/target-k3s"
  for_each = local.provider == "k3s" ? local.apps : {}

  name      = each.key
  app       = each.value
  base_dir  = "${local.project}/apps"
  domain    = local.domain
  namespace = kubernetes_namespace_v1.mnmv[0].metadata[0].name
  registry  = var.registry
}

output "urls" {
  value = { for k, m in module.k3s : k => m.url }
}
