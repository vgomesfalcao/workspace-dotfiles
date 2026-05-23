#!/usr/bin/env bash
# workspace-setup.sh
# Configura um workspace remoto (VPS) do zero — sem dependência de arquivos locais.
# Uso: bash workspace-setup.sh <host_ssh>
# Exemplos:
#   bash workspace-setup.sh workspace          # alias em ~/.ssh/config
#   bash workspace-setup.sh ubuntu@1.2.3.4     # user@ip direto
#
# Requisitos mínimos: ssh e bash na máquina onde este script é executado.

set -euo pipefail

# ─── Alvo ────────────────────────────────────────────────────────────────────
REMOTE_HOST="${1:-}"
if [[ -z "$REMOTE_HOST" ]]; then
  echo "Uso: bash workspace-setup.sh <host_ssh>"
  echo "Exemplo: bash workspace-setup.sh workspace"
  exit 1
fi

# ─── Cores ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

command -v ssh >/dev/null || error "ssh não encontrado"

info "Configurando workspace remoto: $REMOTE_HOST"

# ─── Fase 1: instalação de ferramentas ───────────────────────────────────────
info "Fase 1/2 — instalando ferramentas no servidor..."

ssh "$REMOTE_HOST" 'bash -s' << 'REMOTE_INSTALL'
#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[remote]${NC} $*"; }
warn() { echo -e "${YELLOW}[remote]${NC} $*"; }

# ── Pacotes base ──────────────────────────────────────────────────────────────
info "Atualizando pacotes..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  zsh tmux vim git curl wget unzip build-essential \
  ca-certificates gnupg lsb-release \
  ripgrep fd-find fzf bat htop \
  2>/dev/null || true

# ── zsh como shell padrão ─────────────────────────────────────────────────────
if [[ "$SHELL" != "$(which zsh)" ]]; then
  info "Definindo zsh como shell padrão..."
  sudo chsh -s "$(which zsh)" "$USER" \
    || warn "chsh falhou — execute manualmente: sudo chsh -s \$(which zsh) \$USER"
fi

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────
if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  info "Instalando oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  info "oh-my-zsh já instalado"
fi

# ── Spaceship prompt ──────────────────────────────────────────────────────────
SPACESHIP_DIR="$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"
if [[ ! -d "$SPACESHIP_DIR" ]]; then
  info "Instalando spaceship prompt..."
  git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git \
    "$SPACESHIP_DIR" 2>/dev/null
else
  info "spaceship já instalado"
fi
ln -sf "$SPACESHIP_DIR/spaceship.zsh-theme" \
  "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme" 2>/dev/null || true

# ── zinit ─────────────────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.local/share/zinit/zinit.git" ]]; then
  info "Instalando zinit..."
  mkdir -p "$HOME/.local/share/zinit"
  chmod g-rwX "$HOME/.local/share/zinit"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit \
    "$HOME/.local/share/zinit/zinit.git" 2>/dev/null
else
  info "zinit já instalado"
fi

# ── tmux TPM + plugins ────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  info "Instalando TPM..."
  mkdir -p "$HOME/.tmux/plugins"
  git clone --depth=1 https://github.com/tmux-plugins/tpm \
    "$HOME/.tmux/plugins/tpm" 2>/dev/null
else
  info "TPM já instalado"
fi

# ── mise ──────────────────────────────────────────────────────────────────────
if [[ ! -f "$HOME/.local/bin/mise" ]]; then
  info "Instalando mise..."
  curl -fsSL https://mise.run | sh
else
  info "mise já instalado"
fi

# ── bun ───────────────────────────────────────────────────────────────────────
if [[ ! -f "$HOME/.bun/bin/bun" ]]; then
  info "Instalando bun..."
  curl -fsSL https://bun.sh/install | bash
else
  info "bun já instalado"
fi

# ── Symlinks bat / fd (nomes alternativos no Ubuntu) ─────────────────────────
mkdir -p "$HOME/.local/bin"
[[ -f /usr/bin/batcat && ! -L "$HOME/.local/bin/bat" ]] && \
  ln -sf /usr/bin/batcat "$HOME/.local/bin/bat" || true
[[ -f /usr/bin/fdfind && ! -L "$HOME/.local/bin/fd" ]] && \
  ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd" || true

# ── fzf keybindings ───────────────────────────────────────────────────────────
FZF_EX=/usr/share/doc/fzf/examples
if [[ -d "$FZF_EX" ]]; then
  mkdir -p "$HOME/.fzf"
  cp "$FZF_EX/key-bindings.zsh" "$HOME/.fzf/" 2>/dev/null || true
  cp "$FZF_EX/completion.zsh"   "$HOME/.fzf/" 2>/dev/null || true
fi

info "Ferramentas instaladas."
REMOTE_INSTALL

# ─── Fase 2: gravar dotfiles embutidos no servidor ───────────────────────────
info "Fase 2/2 — gravando dotfiles..."

# ── .zshrc ───────────────────────────────────────────────────────────────────
ssh "$REMOTE_HOST" 'tee ~/.zshrc > /dev/null' << 'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"

plugins=(git z ssh-agent)

source $ZSH/oh-my-zsh.sh

# ── Spaceship ────────────────────────────────────────────────────────────────
SPACESHIP_PROMPT_ORDER=(
  user dir host git hg exec_time line_sep jobs exit_code char
)
SPACESHIP_USER_SHOW=always
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

# ── zinit ────────────────────────────────────────────────────────────────────
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  mkdir -p "$HOME/.local/share/zinit" && chmod g-rwX "$HOME/.local/share/zinit"
  git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

zinit light zdharma/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# ── SSH agent forwarding ──────────────────────────────────────────────────────
zstyle :omz:plugins:ssh-agent agent-forwarding on

# ── PATH e ferramentas ────────────────────────────────────────────────────────
export PATH=/usr/bin:/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# mise
[[ -f "$HOME/.local/bin/mise" ]] && eval "$($HOME/.local/bin/mise activate zsh)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# fzf
[ -f ~/.fzf/key-bindings.zsh ] && source ~/.fzf/key-bindings.zsh
[ -f ~/.fzf/completion.zsh   ] && source ~/.fzf/completion.zsh
ZSHRC
info "  ✔ .zshrc"

# ── .tmux.conf ───────────────────────────────────────────────────────────────
ssh "$REMOTE_HOST" 'tee ~/.tmux.conf > /dev/null' << 'TMUXCONF'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'

set -g mouse on

run -b '~/.tmux/plugins/tpm/tpm'
TMUXCONF
info "  ✔ .tmux.conf"

# ── .vimrc ────────────────────────────────────────────────────────────────────
ssh "$REMOTE_HOST" 'tee ~/.vimrc > /dev/null' << 'VIMRC'
set number
syntax on
colorscheme industry
set tabstop=2
set clipboard=unnamedplus
VIMRC
info "  ✔ .vimrc"

# ── .gitconfig ────────────────────────────────────────────────────────────────
ssh "$REMOTE_HOST" 'tee ~/.gitconfig > /dev/null' << 'GITCONFIG'
[user]
	email = vgomesfalcao@gmail.com
	name = Vinicius Gomes Falcão
[pack]
	windowMemory = 32m
[pull]
	rebase = true
GITCONFIG
info "  ✔ .gitconfig"

# ── plugins do tmux (headless) ────────────────────────────────────────────────
ssh "$REMOTE_HOST" \
  'TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins ~/.tmux/plugins/tpm/bin/install_plugins 2>/dev/null || true'
info "  ✔ plugins tmux instalados"

info ""
info "========================================"
info " Workspace pronto!"
info " Próximos passos:"
info "   ssh $REMOTE_HOST"
info "   exec zsh"
info "========================================"
