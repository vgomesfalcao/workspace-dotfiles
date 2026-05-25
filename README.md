# workspace-dotfiles

Scripts para provisionar e operar um workspace remoto Ubuntu (ARM64) com Docker e Tailscale.

---

## Conteúdo

| Arquivo | Descrição |
|---|---|
| `workspace-setup.sh` | Provisiona um servidor do zero (shell, ferramentas, dotfiles) |
| `docker-tailscale-proxy.sh` | Monitora Docker e cria proxies HTTPS automáticos via Tailscale Serve |

---

## workspace-setup.sh

Configura um servidor Ubuntu remoto do zero via SSH. Não depende de arquivos locais — tudo é embutido no script.

### O que instala

| Ferramenta | Descrição |
|---|---|
| zsh + oh-my-zsh | Shell com framework de configuração |
| spaceship-prompt | Tema minimalista e informativo |
| zinit | Gerenciador de plugins zsh |
| fast-syntax-highlighting | Highlight de sintaxe no terminal |
| zsh-autosuggestions | Sugestões baseadas no histórico |
| zsh-completions | Completions extras |
| tmux + TPM | Multiplexador de terminal |
| tmux-sensible + tmux-resurrect | Plugins tmux: defaults + salvar sessões |
| vim | Editor com configuração base |
| mise | Gerenciador de versões (node, python, ruby…) |
| bun | Runtime e gerenciador de pacotes JS |
| ripgrep, fd, fzf, bat, htop | Ferramentas CLI modernas |

### Uso

```bash
# Com alias do ~/.ssh/config
bash workspace-setup.sh workspace

# Com user@ip direto
bash workspace-setup.sh ubuntu@1.2.3.4
```

### Requisitos

- `bash` e `ssh` na máquina local
- Acesso SSH ao servidor de destino
- O usuário remoto deve ter `sudo` sem senha (padrão em VPS Ubuntu)

---

## docker-tailscale-proxy.sh

Monitora eventos Docker e cria automaticamente proxies HTTPS via **Tailscale Serve** sempre que um container sobe.

### Comportamento

- Containers em porta **80 / 443 / 8080 / 8443** → porta HTTPS dedicada (`:8800`, `:8801`…) para não quebrar assets de apps web com URLs absolutas (Drupal, Laravel, etc.)
- Demais containers com porta mapeada → caminho `/<nome>` no domínio Tailscale
- Ao iniciar, processa containers já em execução
- Roda como serviço de usuário systemd

### Instalação no servidor

```bash
mkdir -p ~/scripts
cp docker-tailscale-proxy.sh ~/scripts/
chmod +x ~/scripts/docker-tailscale-proxy.sh

# Permissão para rodar tailscale serve sem sudo
sudo tailscale set --operator=$USER

# Serviço systemd de usuário
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/docker-proxy.service << 'EOF'
[Unit]
Description=Docker Tailscale Proxy Monitor
After=default.target

[Service]
Type=simple
ExecStart=/home/SEU_USUARIO/scripts/docker-tailscale-proxy.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

sudo loginctl enable-linger $USER
systemctl --user daemon-reload
systemctl --user enable --now docker-proxy.service
```

### Comandos úteis

```bash
tailscale serve status                          # ver mapeamentos ativos
journalctl --user -u docker-proxy.service -f   # logs em tempo real
systemctl --user status docker-proxy.service   # status do serviço
```

---

## Como os serviços Docker ficam acessíveis

Quando um container sobe no workspace, três caminhos de acesso coexistem automaticamente:

```
Container sobe no workspace com porta 8080
    │
    ├─► Docker expõe: workspace-ip:8080 (acesso direto)
    │
    ├─► VS Code tunnel detecta :8080 → faz port-forward → localhost:8080 na sua máquina
    │
    └─► docker-tailscale-proxy.sh detecta o container →
        tailscale serve --https=8800 http://localhost:8080 →
        https://workspace.TAILNET.ts.net:8800
```

| Endereço | Mecanismo | Quem acessa |
|---|---|---|
| `http://workspace:8080` | Tailscale MagicDNS resolve o hostname direto | Qualquer dispositivo no Tailnet |
| `http://localhost:8080` | VS Code tunnel faz port-forward automático | Só você, via VS Code |
| `https://workspace.TAILNET.ts.net:8800` | Tailscale Serve (HTTPS com certificado) | Qualquer dispositivo no Tailnet |

### MagicDNS — o atalho mais prático

Com o Tailscale ativo nos dois dispositivos, o hostname `workspace` resolve automaticamente para o IP Tailscale do servidor. Então `http://workspace:8080` funciona direto no browser — sem precisar lembrar IP ou domínio longo.

Para desenvolvimento do dia a dia, esse é o caminho mais simples. O Tailscale Serve (HTTPS) é útil quando precisa de:
- Certificado HTTPS válido
- Acesso de dispositivos mobile
- Exposição via Funnel (internet pública fora do Tailnet)

### Desativar port-forward automático do VS Code

Se os serviços aparecerem em lugares demais, desative o forward automático no `settings.json`:

```json
"remote.autoForwardPorts": false
```
