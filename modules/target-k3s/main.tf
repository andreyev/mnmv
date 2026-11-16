locals {
  build_dir  = abspath("${var.base_dir}/${var.app.build}")
  dockerfile = file("${local.build_dir}/Dockerfile")

  # Convenção: porta = primeiro EXPOSE do Dockerfile; senão 80.
  exposed = try(tonumber(regex("(?mi)^\\s*EXPOSE\\s+(\\d+)", local.dockerfile)[0]), null)
  port    = coalesce(var.app.port, local.exposed, 80)

  # A tag é o hash do conteúdo do diretório: código novo => tag nova => rollout novo.
  src_hash = sha1(join("", [
    for f in sort(fileset(local.build_dir, "**")) : filesha1("${local.build_dir}/${f}")
  ]))
  image = "${var.registry}/${var.name}:${substr(local.src_hash, 0, 12)}"

  host = "${var.name}.${var.domain}"

  sizes = {
    small  = { requests = { cpu = "50m", memory = "64Mi" }, limits = { memory = "128Mi" } }
    medium = { requests = { cpu = "200m", memory = "256Mi" }, limits = { memory = "512Mi" } }
    large  = { requests = { cpu = "500m", memory = "512Mi" }, limits = { memory = "1Gi" } }
  }
}

# Build + push para o registry local, só quando o conteúdo muda.
resource "terraform_data" "image" {
  triggers_replace = [local.image]

  provisioner "local-exec" {
    command = "docker build -t '${local.image}' '${local.build_dir}' && docker push '${local.image}'"
  }
}

resource "kubernetes_deployment_v1" "this" {
  depends_on = [terraform_data.image]

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = { app = var.name, "app.kubernetes.io/managed-by" = "mnmv" }
  }

  spec {
    replicas = var.app.replicas
    selector { match_labels = { app = var.name } }

    template {
      metadata { labels = { app = var.name } }

      spec {
        container {
          name  = var.name
          image = local.image

          port { container_port = local.port }

          env {
            name  = "PORT"
            value = tostring(local.port)
          }

          dynamic "env" {
            for_each = var.app.env
            content {
              name  = env.key
              value = env.value
            }
          }

          resources {
            requests = local.sizes[var.app.size].requests
            limits   = local.sizes[var.app.size].limits
          }

          readiness_probe {
            tcp_socket { port = local.port }
            period_seconds = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = { app = var.name }
    port {
      port        = 80
      target_port = local.port
    }
  }
}

# k3s já vem com Traefik como ingress controller.
resource "kubernetes_ingress_v1" "this" {
  count = var.app.public ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = local.host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.this.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}
