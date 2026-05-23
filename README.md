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
