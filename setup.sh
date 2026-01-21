#!/usr/bin/env bash

# Git configuration
git config --global push.autoSetupRemote true

# Install Claude Code CLI
echo "Installing Claude Code CLI..."
if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-cli
else
    echo "Claude CLI already installed"
fi

# Install OpenAI Codex CLI
echo "Installing OpenAI Codex CLI..."
if ! command -v codex &> /dev/null; then
    npm install -g openai-codex-cli
else
    echo "OpenAI Codex CLI already installed"
fi

# Create symlink for intent-detection-setup script
echo "Setting up intent-detection-setup script..."
DOTFILES_PATH="/workspaces/.codespaces/.persistedshare/dotfiles"
if [ -f "$DOTFILES_PATH/intent-detection-setup.sh" ]; then
    ln -sf "$DOTFILES_PATH/intent-detection-setup.sh" ~/intent-detection-setup.sh
    echo "Created symlink: ~/intent-detection-setup.sh"
fi

# Add intent-detection-setup alias to bashrc
if ! grep -q "alias intent-detection-setup=" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'EOF'

# Intent Detection Setup
alias intent-detection-setup='/workspaces/.codespaces/.persistedshare/dotfiles/intent-detection-setup.sh'
EOF
    echo "Added intent-detection-setup alias to ~/.bashrc"
fi

echo "Setup complete!"
echo ""
echo "To set up intent detection environment, run:"
echo "  ~/intent-detection-setup.sh"
echo "  OR (after reopening terminal)"
echo "  intent-detection-setup"
