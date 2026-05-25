# VS Code no workspace remoto

## VS Code Tunnel

O tunnel expõe o workspace remotamente via `vscode.dev` sem precisar abrir portas. Funciona mesmo sem IP público.

### Instalar e autenticar (primeira vez)

```bash
# Baixar o binário code (ARM64)
curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64' \
  --output /tmp/vscode_cli.tar.gz
tar -xf /tmp/vscode_cli.tar.gz -C /usr/local/bin

# Autenticar via GitHub (abre link no browser)
code tunnel --accept-server-license-terms
```

### Configurar como serviço systemd (sistema)

Usar serviço de sistema (`/etc/systemd/system/`) em vez de usuário evita o problema de `HOME` stale — veja [systemd.md](systemd.md).

```bash
sudo tee /etc/systemd/system/code-tunnel.service << 'EOF'
[Unit]
Description=Visual Studio Code Tunnel
After=network.target

[Service]
Type=simple
User=SEU_USUARIO
ExecStart=/usr/local/bin/code tunnel --accept-server-license-terms
Restart=always
RestartSec=10
Environment=HOME=/home/SEU_USUARIO

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now code-tunnel.service
```

### Verificar status

```bash
sudo systemctl status code-tunnel.service
journalctl -u code-tunnel.service -f
```

---

## Port forwarding automático

O VS Code detecta portas abertas no workspace e faz forward automático para `localhost` na máquina local. Isso faz os serviços Docker aparecerem também em `localhost:PORTA`.

Para desativar (se quiser controlar o acesso só via Tailscale):

```json
// settings.json
"remote.autoForwardPorts": false
```

---

## Servidores MCP

Servidores MCP com `"type": "stdio"` e `"command": "npx"` rodam **localmente** (na máquina com VS Code), não no workspace remoto.

### Problema: `spawn npx ENOENT`

O VS Code não carrega o PATH do shell — não enxerga o `npx` instalado via mise ou nvm.

**Solução no Linux/WSL:** criar symlink em `/usr/local/bin/`:

```bash
sudo ln -sf $(which npx) /usr/local/bin/npx
```

**Solução no Windows:** instalar Node.js para o Windows (não basta ter no WSL):

```powershell
winget install --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
```

Após instalar, reiniciar o VS Code para recarregar o PATH.

### mcp.json global

Localização do arquivo de configuração MCP global:

- **Windows:** `%APPDATA%\Code\User\mcp.json`
- **Linux/WSL:** `~/.config/Code/User/mcp.json`

Exemplo de servidor usando caminho absoluto (evita problemas de PATH):

```json
{
  "servers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```
