#!/bin/bash
set -e

echo "=== dotfiles install ==="

if ! command -v zsh >/dev/null; then
  echo "-> ставлю zsh"
  sudo apt update && sudo apt install -y zsh
fi
if ! command -v git >/dev/null; then
  echo "-> ставлю git"
  sudo apt update && sudo apt install -y git
fi

KEYNAME="id_ed25519_dotfiles"
KEYPATH="$HOME/.ssh/$KEYNAME"
if [ ! -f "$KEYPATH" ]; then
  HOSTLABEL=$(hostname)
  read -p "Имя для ключа (по умолчанию: $HOSTLABEL): " KEYLABEL
  KEYLABEL="${KEYLABEL:-$HOSTLABEL}"
  ssh-keygen -t ed25519 -f "$KEYPATH" -C "$KEYLABEL" -N ""
  echo ""
  echo "Добавь этот публичный ключ на https://github.com/settings/ssh/new :"
  echo ""
  cat "$KEYPATH.pub"
  echo ""
  read -p "Нажми Enter когда добавишь ключ на GitHub..."
fi

grep -q "IdentityFile $KEYPATH" ~/.ssh/config 2>/dev/null || cat >> ~/.ssh/config << SSHEOF
Host github.com
  HostName github.com
  User git
  IdentityFile $KEYPATH
  IdentitiesOnly yes
SSHEOF

echo "-> проверка SSH"
ssh -T git@github.com || true

if [ ! -d ~/dotfiles ]; then
  git clone git@github.com:QueryWorm/dotfiles.git ~/dotfiles
else
  echo "-> ~/dotfiles уже есть, пропускаю clone"
fi

read -p "DOTFILES_ROLE для этой машины (например: masha, pi, proxmox, debi-wsl): " ROLE
if [ -z "$ROLE" ]; then
  echo "роль не указана, выхожу"; exit 1
fi

mkdir -p ~/dotfiles/zsh/hosts
touch ~/dotfiles/zsh/hosts/$ROLE.zsh

BOOTSTRAP_MARK="# dotfiles bootstrap"
if ! grep -q "$BOOTSTRAP_MARK" ~/.zshrc 2>/dev/null; then
  cat > ~/.zshrc << ZSHEOF
$BOOTSTRAP_MARK
source ~/dotfiles/zsh/.zsh_env
source ~/dotfiles/zsh/.zsh_ui
source ~/dotfiles/zsh/.zsh_aliases
source ~/dotfiles/zsh/.zsh_functions
source ~/dotfiles/zsh/.zsh_dev
DOTFILES_ROLE="$ROLE"
[[ -f ~/dotfiles/zsh/hosts/\$DOTFILES_ROLE.zsh ]] && \\
  source ~/dotfiles/zsh/hosts/\$DOTFILES_ROLE.zsh
ZSHEOF
  echo "-> .zshrc записан"
else
  echo "-> .zshrc уже содержит dotfiles bootstrap, не трогаю (правь руками если нужно)"
fi

if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
  echo "-> дефолтный шелл сменён на zsh (нужен новый логин чтобы применилось)"
fi

echo ""
echo "=== готово: роль '$ROLE' ==="

if [ -z "$(git config --global user.email)" ]; then
  read -p "git user.email (например noreply-адрес с GitHub): " GITEMAIL
  git config --global user.email "$GITEMAIL"
fi
if [ -z "$(git config --global user.name)" ]; then
  read -p "git user.name: " GITNAME
  git config --global user.name "$GITNAME"
fi
