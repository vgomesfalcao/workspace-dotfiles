# Provisionamento do workspace

O script `workspace-setup.sh` configura um servidor Ubuntu remoto do zero via SSH. Não depende de arquivos locais — tudo é embutido no script.

## Uso

```bash
# Com alias do ~/.ssh/config
bash scripts/workspace-setup.sh workspace

# Com user@ip direto
bash scripts/workspace-setup.sh ubuntu@1.2.3.4
```

## O que é instalado

### Shell e terminal

| Ferramenta | Descrição |
|---|---|
| zsh | Shell principal |
| oh-my-zsh | Framework de configuração do zsh |
| spaceship-prompt | Tema com git, node, python, etc. |
| zinit | Gerenciador de plugins zsh |
| fast-syntax-highlighting | Highlight de sintaxe em tempo real |
| zsh-autosuggestions | Sugestões baseadas no histórico |
| zsh-completions | Completions extras |
| tmux + TPM | Multiplexador de terminal |
| tmux-sensible | Configurações sensatas para tmux |
| tmux-resurrect | Salva e restaura sessões tmux |

### Ferramentas CLI

| Ferramenta | Descrição |
|---|---|
| ripgrep (`rg`) | grep muito mais rápido |
| fd | find mais intuitivo |
| fzf | fuzzy finder interativo |
| bat | cat com syntax highlight |
| htop | monitor de processos |
| vim | editor com configuração base |

### Gerenciadores de versão

| Ferramenta | Descrição |
|---|---|
| mise | Gerencia versões de node, python, ruby, go… |
| bun | Runtime e gerenciador de pacotes JS alternativo |

## Dotfiles gerados

O script grava os seguintes arquivos no servidor:

- **`~/.zshrc`** — configuração completa do zsh (zinit, spaceship, mise, bun, fzf)
- **`~/.tmux.conf`** — tmux com mouse, TPM e plugins
- **`~/.vimrc`** — numeração de linha, syntax highlight, tab=2
- **`~/.gitconfig`** — nome, email e `pull.rebase = true`

## Primeiros passos após o provisionamento

```bash
ssh workspace
exec zsh                          # ativar zsh na sessão atual
tmux new -s main                  # criar sessão tmux principal
~/.tmux/plugins/tpm/bin/install_plugins  # instalar plugins tmux (se não instalou automaticamente)
```

## Instalar runtimes com mise

Sempre usar mise para instalar node, python, etc. — nunca diretamente via apt:

```bash
mise use --global node@lts         # Node.js LTS
mise use --global python@3.12      # Python
mise use --global go@latest        # Go
```

### Expor binários globalmente (para VS Code, systemd, etc.)

O mise usa shims em `~/.local/share/mise/shims/`. Processos que não carregam o shell (VS Code, serviços) não enxergam esse PATH. Para expor globalmente:

```bash
sudo ln -sf ~/.local/share/mise/shims/node /usr/local/bin/node
sudo ln -sf ~/.local/share/mise/shims/npm  /usr/local/bin/npm
sudo ln -sf ~/.local/share/mise/shims/npx  /usr/local/bin/npx
```
