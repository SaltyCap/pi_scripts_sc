#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# Removed set -e as it causes the script to stop if a single command fails (e.g. Tailscale setup)

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting the ultimate tool installation...${NC}"

# 1. Tailscale
echo -e "${GREEN}Installing Tailscale...${NC}"
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=YOUR_KEY_HERE # Optional: add your auth key or run manually later

# 2. Ollama
echo -e "${GREEN}Installing Ollama...${NC}"
curl -fsSL https://ollama.com/install.sh | sh

# 3. Claude Code
echo -e "${GREEN}Installing Claude Code...${NC}"
curl -fsSL https://claude.ai/install.sh | bash

# 4. Node.js & NVM (Prerequisite for Gemini CLI)
echo -e "${GREEN}Installing Node.js and NVM...${NC}"
sudo apt update && sudo apt install -y nodejs npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM into the current shell session so we can use it immediately
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# 5. Gemini CLI
echo -e "${GREEN}Installing Gemini CLI...${NC}"
npm install -g @google/gemini-cli

# 6. Open Claw
echo -e "${GREEN}Installing Open Claw...${NC}"
curl -fsSL https://openclaw.ai/install.sh | bash

# 7. Antigravity
echo -e "${GREEN}Installing Antigravity...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
sudo apt update
sudo apt install -y antigravity

echo -e "${GREEN}✅ All installations complete!${NC}"
