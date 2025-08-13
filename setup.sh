# #!/usr/bin/env bash

DOTFILES_ROOT=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)

# .bashrc setup
cp $DOTFILES_ROOT/.bashrc_dotfiles $HOME/.bashrc_dotfiles
echo "source $HOME/.bashrc_dotfiles" >> "$HOME/.bashrc"

# Git Config Setup
git config --global push.autoSetupRemote true
