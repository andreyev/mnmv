# MNMV — Minha Nuvem, Minha Vida (POC)

Aponte para o diretório da sua aplicação; o MNMV builda a imagem e faz o deploy no k3s local.

O seu projeto **não tem nenhum arquivo OpenTofu**, só isto:

```
meu-projeto/
├── cloud.yaml          # provider: k3s, domain: localhost
└── apps/
    └── hello.yaml      # build: ../hello
```

O código OpenTofu fica neste repositório e é baixado via HTTPS (tarball do GitHub) para `.mnmv/code`
no primeiro uso. O state fica em `.mnmv/terraform.tfstate`. Adicione `.mnmv/` ao `.gitignore`.

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/andreyev/mnmv/main/mnmv -o ~/.local/bin/mnmv
chmod +x ~/.local/bin/mnmv
```

Pré-requisitos: k3s (`curl -sfL https://get.k3s.io | sh -`), Docker e OpenTofu ≥ 1.8.

## Uso

```bash
cd meu-projeto
mnmv setup   # uma vez: registry local, k3s puxando dele, kubeconfig
mnmv up      # builda, publica e faz deploy
curl http://hello.localhost
```

Versão do código: `MNMV_REF=v0.1.0 mnmv update` (branch ou tag). Para desenvolver o próprio MNMV,
aponte para um diretório local: `MNMV_SOURCE=~/src/mnmv mnmv update`.

## Convenções

| O quê            | Convenção                                                   |
|------------------|-------------------------------------------------------------|
| Nome do app      | nome do arquivo em `apps/`                                  |
| Imagem           | `localhost:5000/<nome>:<hash do diretório>` (código novo ⇒ rollout novo) |
| Porta            | primeiro `EXPOSE` do Dockerfile; senão `80`                 |
| URL              | `http://<nome>.<domain>` (padrão `domain: localhost`)       |
| Réplicas/tamanho | `1` / `small`                                               |
| Exposição        | pública via Traefik (Ingress padrão do k3s)                 |

Campos opcionais em `apps/<nome>.yaml`: `port`, `replicas`, `public`, `size` (small|medium|large), `env`.

## Limitações conhecidas

- O hash da tag considera todos os arquivos do diretório (não respeita `.dockerignore`).
- Só o alvo `k3s` existe por enquanto.
