# workspace-setup

Script bash para configurar um workspace.

## O que instala

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

## Uso

```bash
# Com alias do ~/.ssh/config
bash workspace-setup.sh workspace

# Com user@ip direto
bash workspace-setup.sh ubuntu@1.2.3.4
```

## Requisitos

- `bash` e `ssh` na máquina de onde o script é executado
- Acesso SSH ao servidor de destino
- O usuário remoto deve ter `sudo` sem senha (padrão em VPS Ubuntu)

---

## docker-tailscale-proxy.sh

Monitora eventos Docker e cria automaticamente proxies HTTPS via **Tailscale Serve**.

- Containers em porta **80/443/8080/8443** → porta HTTPS dedicada (ex: `:8800/`) para não quebrar assets de apps web (Drupal, Laravel, etc.)
- Demais containers com porta mapeada → caminho `/<nome>` no domínio Tailscale
- Ao iniciar, processa containers já em execução
- Roda como serviço de usuário systemd (`docker-proxy.service`)

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
