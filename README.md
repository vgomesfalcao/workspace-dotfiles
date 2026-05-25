# workspace-dotfiles

Documentação e scripts para provisionar e operar um workspace remoto Ubuntu (ARM64) com Docker, Tailscale e VS Code.

---

## Scripts

| Script | Descrição |
|---|---|
| [`scripts/workspace-setup.sh`](scripts/workspace-setup.sh) | Provisiona um servidor do zero via SSH |
| [`scripts/docker-tailscale-proxy.sh`](scripts/docker-tailscale-proxy.sh) | Monitora Docker e cria proxies HTTPS automáticos via Tailscale Serve |

### Uso rápido

```bash
# Provisionar servidor
bash scripts/workspace-setup.sh workspace

# Ou com user@ip direto
bash scripts/workspace-setup.sh ubuntu@1.2.3.4
```

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [Provisionamento](docs/provisionamento.md) | Ferramentas instaladas, dotfiles, primeiros passos |
| [VS Code](docs/vscode.md) | Tunnel remoto, serviço systemd, servidores MCP |
| [Tailscale](docs/tailscale.md) | MagicDNS, Serve, Funnel, proxy Docker automático |
| [Docker](docs/docker.md) | Networking, conflitos de porta, docker-compose.override |
| [systemd](docs/systemd.md) | Serviços de usuário, linger, problemas de HOME |

---

## Pré-requisitos

- Ubuntu 22.04+ (testado em ARM64)
- `bash` e `ssh` na máquina local
- Usuário remoto com `sudo` sem senha (padrão em VPS Ubuntu)
- Tailscale instalado no servidor e na máquina local
