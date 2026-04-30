# pi_scripts_sc

A collection of utility scripts for setting up a Raspberry Pi development environment.

## Scripts

### `install_tools.sh`
This script automates the installation of several essential developer tools:
1. Tailscale
2. Docker Engine, Docker Compose plugin, and Docker Swarm
3. Claude Code
4. Node.js & NVM
5. Gemini CLI
6. Antigravity

**Usage:**

To run the script locally without changing permissions:
```bash
bash install_tools.sh
```

**Run Directly:**
You can run the installation in a single command without downloading the file first:
```bash
curl -fsSL https://raw.githubusercontent.com/SaltyCap/pi_scripts_sc/refs/heads/main/install_tools.sh | bash
```

**Note:** You may need to provide your Tailscale auth key when prompted, or edit the script to include it directly.

Docker Swarm is initialized automatically after Docker installs. By default, the script uses the Pi's Tailscale IPv4 address as the Swarm advertise address when available, then falls back to the first local network IP. To choose the advertise address yourself:
```bash
SWARM_ADVERTISE_ADDR=192.168.1.50 bash install_tools.sh
```
