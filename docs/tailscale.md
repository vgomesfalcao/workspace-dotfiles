# Tailscale no workspace

## MagicDNS — acesso por hostname

Com Tailscale ativo nos dois dispositivos, o hostname de cada máquina resolve automaticamente via DNS privado da rede Tailscale (Tailnet).

```
http://workspace:8080   →  resolve para 100.x.x.x:8080 automaticamente
```

Para desenvolvimento do dia a dia, esse é o caminho mais simples. Não precisa lembrar IP ou domínio longo.

### Verificar o hostname do servidor

```bash
tailscale status
# ou
tailscale status --json | python3 -c "import sys,json; print(json.load(sys.stdin)['Self']['DNSName'])"
```

---

## Tailscale Serve — HTTPS automático

O `tailscale serve` expõe um serviço local via HTTPS com certificado válido no domínio Tailscale.

### Configurar permissão (sem sudo)

```bash
sudo tailscale set --operator=$USER
```

### Expor via caminho (APIs, serviços sem assets)

```bash
tailscale serve --bg --set-path /api http://localhost:3000
# acesso: https://workspace.TAILNET.ts.net/api
```

### Expor via porta dedicada (apps web com assets)

Apps com URLs absolutas de assets (Drupal, Laravel, Next.js) quebram quando servidos em subcaminho. Use porta dedicada:

```bash
tailscale serve --bg --https=8800 http://localhost:8080
# acesso: https://workspace.TAILNET.ts.net:8800
```

### Ver mapeamentos ativos

```bash
tailscale serve status
```

### Remover um mapeamento

```bash
tailscale serve --https=8800 off
tailscale serve --set-path /api off
```

---

## Proxy Docker automático

O script `scripts/docker-tailscale-proxy.sh` monitora eventos Docker e cria os proxies Tailscale Serve automaticamente.

**Regra:**
- Container em porta 80 / 443 / 8080 / 8443 → porta HTTPS dedicada (`:8800`, `:8801`…)
- Outros containers com porta mapeada → caminho `/<nome-do-container>`

### Instalação como serviço

```bash
mkdir -p ~/scripts
cp scripts/docker-tailscale-proxy.sh ~/scripts/
chmod +x ~/scripts/docker-tailscale-proxy.sh

sudo tailscale set --operator=$USER

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

### Logs

```bash
journalctl --user -u docker-proxy.service -f
```

---

## Tailscale Funnel — expor para a internet pública

Para expor um serviço fora do Tailnet (internet pública), use Funnel:

```bash
tailscale funnel --bg --https=443 http://localhost:8080
```

Requer habilitar Funnel nas configurações do Tailnet admin.

---

## Como os serviços Docker ficam acessíveis

Quando um container sobe no workspace, três caminhos coexistem:

```
Container porta 8080 no workspace
    │
    ├─► http://workspace:8080          (MagicDNS — direto)
    ├─► http://localhost:8080          (VS Code tunnel port-forward)
    └─► https://workspace.TAILNET:8800 (Tailscale Serve HTTPS)
```

| Endereço | Mecanismo | Quem acessa |
|---|---|---|
| `http://workspace:8080` | MagicDNS resolve hostname direto | Qualquer dispositivo no Tailnet |
| `http://localhost:8080` | VS Code tunnel faz port-forward | Só você, via VS Code |
| `https://workspace.TAILNET.ts.net:8800` | Tailscale Serve com certificado | Qualquer dispositivo no Tailnet |
