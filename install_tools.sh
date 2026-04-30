#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# Removed set -e as it causes the script to stop if a single command fails (e.g. Tailscale setup)

GREEN='\033[0;32m'
NC='\033[0m'

ensure_path_entry() {
  local path_entry="$1"
  local profile_file

  case ":$PATH:" in
    *":$path_entry:"*) ;;
    *) export PATH="$path_entry:$PATH" ;;
  esac

  for profile_file in "$HOME/.bashrc" "$HOME/.profile"; do
    [ -f "$profile_file" ] || touch "$profile_file"
    if ! grep -Fq "$path_entry" "$profile_file"; then
      echo "export PATH=\"$path_entry:\$PATH\"" >> "$profile_file"
    fi
  done

  if [ -f "$HOME/.zshrc" ] && ! grep -Fq "$path_entry" "$HOME/.zshrc"; then
    profile_file="$HOME/.zshrc"
    echo "export PATH=\"$path_entry:\$PATH\"" >> "$profile_file"
  fi
}

setup_common_paths() {
  ensure_path_entry "/usr/local/bin"
  ensure_path_entry "$HOME/.local/bin"
  ensure_path_entry "$HOME/bin"
  hash -r
}

setup_nvm_profile() {
  local profile_file

  for profile_file in "$HOME/.bashrc" "$HOME/.profile"; do
    [ -f "$profile_file" ] || touch "$profile_file"
    if ! grep -Fq 'NVM_DIR="$HOME/.nvm"' "$profile_file"; then
      {
        echo 'export NVM_DIR="$HOME/.nvm"'
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
      } >> "$profile_file"
    fi
  done

  if [ -f "$HOME/.zshrc" ] && ! grep -Fq 'NVM_DIR="$HOME/.nvm"' "$HOME/.zshrc"; then
    {
      echo 'export NVM_DIR="$HOME/.nvm"'
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    } >> "$HOME/.zshrc"
  fi
}

verify_command() {
  local command_name="$1"
  local version_arg="${2:---version}"

  hash -r

  if command -v "$command_name" >/dev/null 2>&1; then
    echo -e "${GREEN}$command_name is ready:${NC}"
    "$command_name" "$version_arg" 2>/dev/null || command -v "$command_name"
  else
    echo "$command_name was installed, but the command was not found on PATH."
    echo "Open a new terminal, then run: $command_name"
  fi
}

echo -e "${GREEN}🚀 Starting the ultimate tool installation...${NC}"
setup_common_paths

# 1. Tailscale
echo -e "${GREEN}Installing Tailscale...${NC}"
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=YOUR_KEY_HERE # Optional: add your auth key or run manually later
verify_command tailscale version

# 2. Docker Engine & Swarm
echo -e "${GREEN}Installing Docker Engine...${NC}"
curl -fsSL https://get.docker.com | sh
sudo apt install -y docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
verify_command docker --version
if docker compose version >/dev/null 2>&1; then
  echo -e "${GREEN}docker compose is ready:${NC}"
  docker compose version
else
  echo "Docker Compose plugin was installed, but docker compose was not found."
  echo "Open a new terminal, then run: docker compose version"
fi

echo -e "${GREEN}Configuring Docker Swarm...${NC}"
if ! sudo docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q '^active$'; then
  SWARM_ADVERTISE_ADDR="${SWARM_ADVERTISE_ADDR:-}"

  if [ -z "$SWARM_ADVERTISE_ADDR" ] && command -v tailscale >/dev/null 2>&1; then
    SWARM_ADVERTISE_ADDR="$(tailscale ip -4 2>/dev/null | head -n 1)"
  fi

  if [ -z "$SWARM_ADVERTISE_ADDR" ]; then
    SWARM_ADVERTISE_ADDR="$(hostname -I | awk '{print $1}')"
  fi

  if [ -n "$SWARM_ADVERTISE_ADDR" ]; then
    sudo docker swarm init --advertise-addr "$SWARM_ADVERTISE_ADDR"
  else
    echo "Could not determine a Docker Swarm advertise address."
    echo "Run this later with: SWARM_ADVERTISE_ADDR=<ip-address> bash install_tools.sh"
  fi
else
  echo -e "${GREEN}Docker Swarm is already active.${NC}"
fi

# 3. Claude Code
echo -e "${GREEN}Installing Claude Code...${NC}"
curl -fsSL https://claude.ai/install.sh | bash
setup_common_paths
verify_command claude --version

# 4. Node.js & NVM (Prerequisite for Gemini CLI)
echo -e "${GREEN}Installing Node.js and NVM...${NC}"
sudo apt update && sudo apt install -y nodejs npm
verify_command node --version
verify_command npm --version
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
setup_nvm_profile

# Load NVM into the current shell session so we can use it immediately
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if command -v nvm >/dev/null 2>&1; then
  nvm install --lts
  setup_common_paths
  verify_command node --version
  verify_command npm --version
else
  echo "NVM was installed, but the nvm command was not found."
  echo "Open a new terminal, then run: nvm install --lts"
fi

# 5. Gemini CLI
echo -e "${GREEN}Installing Gemini CLI...${NC}"
npm install -g @google/gemini-cli
setup_common_paths
verify_command gemini --version

# 6. Antigravity
echo -e "${GREEN}Installing Antigravity...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
sudo apt update
sudo apt install -y antigravity
setup_common_paths
verify_command antigravity --version

echo -e "${GREEN}✅ All installations complete!${NC}"
