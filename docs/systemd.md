# systemd no workspace

## Serviços de usuário vs sistema

| Tipo | Localização unit file | Comando | Inicia sem login? |
|---|---|---|---|
| Sistema | `/etc/systemd/system/` | `sudo systemctl` | Sim |
| Usuário | `~/.config/systemd/user/` | `systemctl --user` | Com linger |

Para serviços de usuário iniciarem sem sessão ativa (ex: após reboot):

```bash
sudo loginctl enable-linger $USER
```

---

## Problema: HOME stale em serviços de usuário

O daemon de serviços de usuário (`user@UID.service`) herda o `HOME` do momento em que foi criado. Se o usuário foi renomeado depois (ex: `ubuntu` → `vgomesfalcao`), o daemon tem `HOME=/home/ubuntu` em vez de `HOME=/home/vgomesfalcao`.

### Diagnóstico

```bash
# Ver PID do daemon de usuário
systemctl --user status | head -3

# Verificar o HOME que o daemon enxerga
cat /proc/PID_DO_DAEMON/environ | tr '\0' '\n' | grep HOME
```

### Solução — symlink (sem reiniciar o daemon)

Reiniciar o `user@UID.service` mataria todas as sessões tmux. A solução sem downtime é criar um symlink:

```bash
sudo ln -sf /home/vgomesfalcao/.config/systemd /home/ubuntu/.config/systemd
```

O daemon com `HOME=/home/ubuntu` passa a encontrar os unit files em `/home/ubuntu/.config/systemd/user/`, que aponta para o diretório correto.

### Solução — usar serviço de sistema

Para serviços críticos, usar `/etc/systemd/system/` e especificar `HOME` explicitamente:

```ini
[Service]
User=vgomesfalcao
Environment=HOME=/home/vgomesfalcao
ExecStart=/usr/local/bin/meu-servico
```

---

## Problema: `%h` no ExecStart

O especificador `%h` no systemd expande para o `HOME` do daemon, não do usuário atual. Se o HOME estiver stale, o caminho fica errado.

**Errado:**
```ini
ExecStart=%h/scripts/meu-script.sh
# Expande para /home/ubuntu/scripts/meu-script.sh (stale)
```

**Correto:**
```ini
ExecStart=/home/vgomesfalcao/scripts/meu-script.sh
```

---

## Verificar linger

```bash
# Verificar se linger está ativo
loginctl show-user $USER | grep Linger

# Verificar via arquivo (mais confiável quando a sessão está ativa)
ls /var/lib/systemd/linger/
```

> **Nota:** `loginctl show-user` pode mostrar `Linger=no` mesmo quando o linger está ativo, se o usuário tem uma sessão aberta. Verificar o arquivo em `/var/lib/systemd/linger/` é mais confiável.

---

## Comandos úteis

```bash
# Listar serviços de usuário
systemctl --user list-units --type=service

# Recarregar após editar unit files
systemctl --user daemon-reload

# Ver logs de um serviço de usuário
journalctl --user -u nome-do-servico.service -f

# Ver logs de um serviço de sistema
journalctl -u nome-do-servico.service -f

# Status com detalhes
systemctl --user status nome-do-servico.service
```
