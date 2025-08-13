# #!/usr/bin/env bash

DOTFILES_ROOT=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)

# .bashrc setup
cp $DOTFILES_ROOT/.bashrc-dotfiles $HOME/.bashrc-dotfiles
echo "source $HOME/.bashrc_dotfiles" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

# Git Config Setup
git config --global push.autoSetupRemote true
