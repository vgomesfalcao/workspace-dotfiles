#!/usr/bin/env bash
# docker-tailscale-proxy.sh
# Monitora eventos Docker e cria proxies HTTPS via Tailscale Serve.
#
# Containers nginx (porta 80/443) → porta HTTPS dedicada (evita quebra de paths)
# Outros containers com porta mapeada → caminho /nome

set -uo pipefail

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# Porta HTTPS base para containers web (80/443). Cada um recebe a próxima livre.
HTTPS_PORT_START=8800

# Containers que devem usar porta dedicada (app web com assets absolutos)
is_web_container() {
  local port="$1"
  [[ "$port" == "80" || "$port" == "443" || "$port" == "8080" || "$port" == "8443" ]]
}

next_free_https_port() {
  local port="$HTTPS_PORT_START"
  while tailscale serve status 2>/dev/null | grep -q ":${port}"; do
    (( port++ ))
  done
  echo "$port"
}

setup_proxy() {
  local container_id="$1"
  local container_name="$2"

  local port
  port=$(docker inspect --format \
    '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{(index $conf 0).HostPort}}{{"\n"}}{{end}}{{end}}' \
    "$container_id" 2>/dev/null | grep -v '^$' | head -1) || true

  if [[ -z "$port" ]]; then
    log "[$container_name] sem porta mapeada — ignorado"
    return 0
  fi

  local hostname
  hostname=$(tailscale status --json 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('Self',{}).get('DNSName','workspace').rstrip('.'))" 2>/dev/null \
    || echo "workspace")

  if is_web_container "$port"; then
    # App web: porta HTTPS dedicada para não quebrar URLs absolutas de assets
    local https_port
    https_port=$(next_free_https_port)
    log "[$container_name] porta $port → HTTPS dedicada :$https_port (app web)"
    local output
    if output=$(tailscale serve --bg --https="$https_port" "http://localhost:$port" 2>&1); then
      log "[$container_name] proxy ativo: https://$hostname:$https_port/"
    else
      log "[$container_name] aviso: $output"
    fi
  else
    # Serviço/API: caminho /nome (assets não são problema)
    log "[$container_name] porta $port → caminho /$container_name"
    local output
    if output=$(tailscale serve --bg --set-path "/$container_name" "http://localhost:$port" 2>&1); then
      log "[$container_name] proxy ativo: https://$hostname/$container_name"
    else
      log "[$container_name] aviso: $output"
    fi
  fi
}

log "Iniciando monitor Docker → Tailscale Proxy (tailscale v$(tailscale version | head -1))"

log "Verificando containers em execução..."
while IFS=" " read -r cid cname; do
  [[ -z "$cid" ]] && continue
  setup_proxy "$cid" "$cname" || true
done < <(docker ps --format "{{.ID}} {{.Names}}" 2>/dev/null)

log "Aguardando novos containers..."

docker events \
  --filter "type=container" \
  --filter "event=start" \
  --format "{{.Actor.ID}} {{.Actor.Attributes.name}}" \
| while IFS=" " read -r container_id container_name; do
  setup_proxy "$container_id" "$container_name" || true
done
