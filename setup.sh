#!/usr/bin/env bash

set -e

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

# Install GitHub Copilot CLI
echo "Installing GitHub Copilot CLI..."
if ! command -v copilot &> /dev/null; then
    npm install -g @github/copilot@prerelease
else
    echo "Copilot CLI already installed"
fi

# Configure Copilot CLI
echo "Configuring Copilot CLI..."
mkdir -p ~/.copilot

# Enable experimental mode, staff features, and set defaults
cat > ~/.copilot/config.json << 'EOF'
{
  "version": 1,
  "data": {
    "banner": "never",
    "theme": "auto"
  },
  "staff": true,
  "experimental": true,
  "banner": "never"
}
EOF

# Configure gopls LSP for Go code intelligence
cat > ~/.copilot/lsp-config.json << 'EOF'
{
  "lspServers": {
    "go": {
      "command": "gopls",
      "args": ["serve"],
      "fileExtensions": {
        ".go": "go"
      }
    }
  }
}
EOF

# Ensure gopls is installed
echo "Ensuring gopls is installed..."
if command -v go &> /dev/null; then
    if ! command -v gopls &> /dev/null; then
        go install golang.org/x/tools/gopls@latest
    else
        echo "gopls already installed"
    fi
else
    echo "Go not found, skipping gopls install"
fi

echo "Setup complete!"
