# Docker no workspace

## Conflito de porta com Tailscale

O Tailscale Serve ocupa a porta 443 do servidor. Se um container tenta mapear `0.0.0.0:443`, o Docker falha ao subir.

### Solução: docker-compose.override.yml

Crie um arquivo local que **não é commitado** para sobrescrever as portas:

```yaml
# docker-compose.override.yml
# NÃO commitar — adicionar ao .gitignore
services:
  nginx:
    ports: !override
      - "80:80"
      - "8443:443"   # remapeia 443 do host para 8443
```

Adicionar ao `.gitignore`:

```
docker-compose.override.yml
```

O Docker Compose mescla automaticamente o `override` com o `docker-compose.yml` principal. Outros desenvolvedores com o arquivo original não são afetados.

### Por que `!override` e não `!reset`?

- `!reset` — zera a lista para `null` (quebra o serviço)
- `!override` — substitui a lista inteira (comportamento correto)

Requer Docker Compose v2.24+ (testado com v5.1.4).

---

## ARM64 — peculiaridades

O workspace roda em ARM64 (aarch64). Alguns problemas comuns:

### libaio — nome do pacote mudou no Debian Bookworm

```dockerfile
# Errado (Ubuntu 20/22, Debian Bullseye)
RUN apt-get install -y libaio1

# Correto (Debian Bookworm / Ubuntu 24)
RUN apt-get install -y libaio1t64
```

Se um binário procura `libaio.so.1` e só existe `libaio.so.1t64`:

```dockerfile
RUN ln -sf /usr/lib/aarch64-linux-gnu/libaio.so.1t64 \
           /usr/lib/aarch64-linux-gnu/libaio.so.1
```

### ext-oci8 — Composer falha na detecção

O PHP consegue carregar a extensão OCI8 em runtime, mas o Composer não consegue detectá-la durante o build (a biblioteca dinâmica falha ao carregar sem um Oracle Client completo disponível).

```dockerfile
RUN composer install --no-interaction --prefer-dist \
    --optimize-autoloader --ignore-platform-req=ext-oci8
```

### Imagens x86 em ARM64

Containers com `platform: linux/amd64` precisam de emulação QEMU. Se o QEMU não está configurado no host, o container falha com `exec format error`.

```bash
# Verificar se emulação está disponível
ls /proc/sys/fs/binfmt_misc/
```

Se não for necessário rodar o container (ex: banco Oracle em servidor externo), simplesmente não suba o container ao invés de tentar emular.

---

## Volume mounts escondem vendor/

Quando o `docker-compose.yml` monta o código-fonte como volume, os arquivos instalados na imagem (como `vendor/` do Composer) ficam ocultos pelo mount.

**Sintoma:** container sobe, mas a aplicação falha com "class not found".

**Solução:** rodar `composer install` dentro do container após o start:

```bash
docker exec -it container_name composer install
```

Para Laravel, criar também os diretórios de storage:

```bash
docker exec container_name bash -c "
  mkdir -p storage/framework/{sessions,views,cache}
  mkdir -p bootstrap/cache
  chmod -R 777 storage bootstrap/cache
"
```

---

## Permissões de storage (Laravel/Symfony)

Em desenvolvimento, quando o uid do container difere do uid do host, o container não consegue escrever em `storage/`.

```bash
docker exec container_name chmod -R 777 /var/www/storage /var/www/bootstrap/cache
```

Isso não persiste se o container for recriado. Para persistir, adicionar ao `entrypoint.sh` da imagem.

---

## Monitorar eventos Docker

```bash
# Ver todos os eventos em tempo real
docker events

# Filtrar só starts de containers
docker events --filter "type=container" --filter "event=start"

# Com formato customizado
docker events \
  --filter "type=container" \
  --filter "event=start" \
  --format "{{.Actor.ID}} {{.Actor.Attributes.name}}"
```
