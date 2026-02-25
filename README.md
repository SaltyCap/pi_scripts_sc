# pi_scripts_sc

A collection of utility scripts for setting up a Raspberry Pi development environment.

## Scripts

### `install_tools.sh`
This script automates the installation of several essential developer tools:
1. Tailscale
2. Ollama
3. Claude Code
4. Node.js & NVM
5. Gemini CLI
6. Open Claw

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
