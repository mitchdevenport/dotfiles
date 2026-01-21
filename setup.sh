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

echo "Setup complete!"
