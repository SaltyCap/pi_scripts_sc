#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# Removed set -e as it causes the script to stop if a single command fails (e.g. Tailscale setup)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

PROGRAMS=(
  "Tailscale"
  "Docker Engine & Swarm"
  "Claude Code"
  "Node.js & NVM"
  "Gemini CLI"
  "Antigravity"
)

SELECTED=()
for index in "${!PROGRAMS[@]}"; do
  SELECTED[$index]=0
done

install_tailscale() {
  echo -e "${GREEN}Installing Tailscale...${NC}"
  curl -fsSL https://tailscale.com/install.sh | sh
  sudo tailscale up --authkey=YOUR_KEY_HERE # Optional: add your auth key or run manually later
  verify_command tailscale version
}

install_docker_swarm() {
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
}

install_claude_code() {
  echo -e "${GREEN}Installing Claude Code...${NC}"
  curl -fsSL https://claude.ai/install.sh | bash
  setup_common_paths
  verify_command claude --version
}

install_node_nvm() {
  echo -e "${GREEN}Installing Node.js and NVM...${NC}"
  sudo apt update && sudo apt install -y nodejs npm
  verify_command node --version
  verify_command npm --version
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  setup_nvm_profile

  # Load NVM into the current shell session so we can use it immediately.
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
}

install_gemini_cli() {
  echo -e "${GREEN}Installing Gemini CLI...${NC}"
  npm install -g @google/gemini-cli
  setup_common_paths
  verify_command gemini --version
}

install_antigravity() {
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
}

draw_menu() {
  local cursor="$1"

  printf '\033[H\033[J'
  echo -e "${GREEN}Select programs to install${NC}"
  echo "Use ↑/↓ or j/k to move, spacebar to select, Enter to install."
  echo "Press a to toggle all, or q to quit."
  echo

  for index in "${!PROGRAMS[@]}"; do
    local pointer=" "
    local marker=" "

    if [ "$index" -eq "$cursor" ]; then
      pointer=">"
    fi

    if [ "${SELECTED[$index]}" -eq 1 ]; then
      marker="x"
    fi

    printf "%s [%s] %s\n" "$pointer" "$marker" "${PROGRAMS[$index]}"
  done
}

toggle_all() {
  local next_value=1

  for selected in "${SELECTED[@]}"; do
    if [ "$selected" -eq 0 ]; then
      next_value=1
      break
    fi
    next_value=0
  done

  for index in "${!SELECTED[@]}"; do
    SELECTED[$index]=$next_value
  done
}

has_selection() {
  for selected in "${SELECTED[@]}"; do
    if [ "$selected" -eq 1 ]; then
      return 0
    fi
  done

  return 1
}

select_programs() {
  local cursor=0
  local input
  local key

  if [ -t 0 ]; then
    input="/dev/stdin"
  elif [ -r /dev/tty ]; then
    input="/dev/tty"
  else
    echo -e "${YELLOW}No interactive terminal found. Installing all programs.${NC}"
    for index in "${!SELECTED[@]}"; do
      SELECTED[$index]=1
    done
    return
  fi

  while true; do
    draw_menu "$cursor"

    IFS= read -rsn1 key < "$input"

    if [[ $key == $'\x1b' ]]; then
      IFS= read -rsn2 key < "$input"
      case "$key" in
        "[A")
          ((cursor--))
          ;;
        "[B")
          ((cursor++))
          ;;
      esac
    else
      case "$key" in
        "k"|"K")
          ((cursor--))
          ;;
        "j"|"J")
          ((cursor++))
          ;;
        " ")
          if [ "${SELECTED[$cursor]}" -eq 1 ]; then
            SELECTED[$cursor]=0
          else
            SELECTED[$cursor]=1
          fi
          ;;
        "a"|"A")
          toggle_all
          ;;
        "")
          if has_selection; then
            break
          fi
          echo -e "${YELLOW}Select at least one program before continuing.${NC}"
          sleep 1
          ;;
        "q"|"Q")
          printf '\033[H\033[J'
          echo -e "${YELLOW}Installation cancelled.${NC}"
          exit 0
          ;;
      esac
    fi

    if [ "$cursor" -lt 0 ]; then
      cursor=$((${#PROGRAMS[@]} - 1))
    elif [ "$cursor" -ge "${#PROGRAMS[@]}" ]; then
      cursor=0
    fi
  done

  printf '\033[H\033[J'
}

echo -e "${GREEN}🚀 Starting the ultimate tool installation...${NC}"
setup_common_paths
select_programs

if [ "${SELECTED[4]}" -eq 1 ] && [ "${SELECTED[3]}" -eq 0 ]; then
  echo -e "${YELLOW}Gemini CLI requires Node.js & NVM, so Node.js & NVM was added to your selection.${NC}"
  SELECTED[3]=1
fi

echo -e "${GREEN}Installing selected programs...${NC}"

[ "${SELECTED[0]}" -eq 1 ] && install_tailscale
[ "${SELECTED[1]}" -eq 1 ] && install_docker_swarm
[ "${SELECTED[2]}" -eq 1 ] && install_claude_code
[ "${SELECTED[3]}" -eq 1 ] && install_node_nvm
[ "${SELECTED[4]}" -eq 1 ] && install_gemini_cli
[ "${SELECTED[5]}" -eq 1 ] && install_antigravity

echo -e "${GREEN}✅ Selected installations complete!${NC}"
