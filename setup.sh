#!/usr/bin/env bash

echo "\033[32mMain dotfiles install script started..."
echo "\033[0m"

DOTFILES_ROOT=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)

generic_install() {
  sudo apt install -o DPkg::Options::="--force-confnew" -y "$1"
}

# ===================
# Basic shell things
# ===================

echo "Installing required tools..."
which zsh || generic_install zsh

if [[ ! -f ~/.oh-my-zsh/oh-my-zsh.sh ]]; then
  if [[ -d ~/.oh-my-zsh ]]; then
    rm -rf ~/.oh-my-zsh
  fi
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

echo "Done\n"

echo "Setting up zshrc..."

# Installing startship
curl -sS https://starship.rs/install.sh | sh

# copy .zshrc itself
cp $DOTFILES_ROOT/.zshrc $HOME/.zshrc
printf "$DOTFILES_ROOT/.zshrc copied to $HOME/.zshrc\n"
source "$HOME/.zshrc"

sudo chsh -s "$(which zsh)" "$(whoami)"
echo "If the default shell changed, you may need to log out and in again for this to take effect."
