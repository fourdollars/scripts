#!/usr/bin/env bash
# Strict bash mode
set -euo pipefail

# bun is a fast, modern JavaScript runtime, compiler, and package manager - https://bun.sh
# Install bun (It will append 'export BUN_INSTALL="$HOME/.bun"; export PATH="$BUN_INSTALL/bin:$PATH"' to $HOME/.bashrc)
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Install AI tools
bun install -g opencode-ai opencode-lmstudio opencode-skills @github/copilot @google/gemini-cli @fission-ai/openspec

# uv is an extremely fast Python package and project manager, written in Rust - https://docs.astral.sh/uv/
# Install uv (It will append '. "$HOME/.local/bin/env"' to $HOME/.bashrc and $HOME/.profile when PATH doesn't contain ~/.local/bin)
curl -LsSf https://astral.sh/uv/install.sh | sh
if ! grep -q "$HOME"/.local/bin <<<"$PATH"; then
    # shellcheck source=/dev/null
    source "$HOME"/.local/bin/env
fi

# Install AI tools
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# Homebrew is a package manager for macOS/Linux - https://brew.sh/
# Install Homebrew (It will append 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' to $HOME/.bashrc)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
if ! grep -q linuxbrew "$HOME"/.bashrc; then
    echo >> "$HOME"/.bashrc
    # shellcheck disable=SC2016
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME"/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    if [ -n "$(command -v apt-get)" ]; then sudo apt-get update && sudo apt-get install build-essential; fi
fi

# Install AI tools
if [ -n "$(command -v brew)" ]; then
    brew install ollama
fi

mkdir -p ~/.claude/skills ~/.copilot/skills ~/.config/opencode/skill ~/skills

if [ -d ~/skills/anthropics-skills ]; then
    cd ~/skills/anthropics-skills && git pull
else
    git clone https://github.com/anthropics/skills.git ~/skills/anthropics-skills
fi
ln -snf ~/skills/anthropics-skills/skills/skill-creator ~/.claude/skills/skill-creator

if [ -d ~/skills/lp-api ]; then
    cd ~/skills/lp-api && git pull
else
    git clone https://github.com/fourdollars/lp-api.git ~/skills/lp-api
fi
ln -snf ~/skills/lp-api/launchpad ~/.claude/skills/launchpad
