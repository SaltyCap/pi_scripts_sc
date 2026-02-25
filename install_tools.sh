#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting the ultimate tool installation..."

# 1. Tailscale
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=YOUR_KEY_HERE # Optional: add your auth key or run manually later

# 2. Ollama
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 3. Claude Code
echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# 4. Node.js & NVM (Prerequisite for Gemini CLI)
echo "Installing Node.js and NVM..."
sudo apt update && sudo apt install -y nodejs npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM into the current shell session so we can use it immediately
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# 5. Gemini CLI
echo "Installing Gemini CLI..."
npm install -g @google/gemini-cli

# 6. Open Claw
echo "Installing Open Claw..."
curl -fsSL https://openclaw.ai/install.sh | bash

echo "✅ All installations complete!"
