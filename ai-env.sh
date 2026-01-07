#!/usr/bin/env bash
# Strict bash mode
set -euo pipefail

# bun is a fast, modern JavaScript runtime, compiler, and package manager - https://bun.sh
if [ -z "$(command -v bun)" ]; then
    # Install bun (It will append 'export BUN_INSTALL="$HOME/.bun"; export PATH="$BUN_INSTALL/bin:$PATH"' to $HOME/.bashrc)
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
else
    bun upgrade
fi

# Install AI tools
bun install -g opencode-ai opencode-lmstudio opencode-skills @github/copilot @google/gemini-cli @fission-ai/openspec

# uv is an extremely fast Python package and project manager, written in Rust - https://docs.astral.sh/uv/
if [ -z "$(command -v uv)" ]; then
    # Install uv (It will append '. "$HOME/.local/bin/env"' to $HOME/.bashrc and $HOME/.profile when PATH doesn't contain ~/.local/bin)
    curl -LsSf https://astral.sh/uv/install.sh | sh
    if ! grep -q "$HOME"/.local/bin <<<"$PATH"; then
        # shellcheck source=/dev/null
        source "$HOME"/.local/bin/env
    fi
else
    uv self update
fi

# Install AI tools
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# Homebrew is a package manager for macOS/Linux - https://brew.sh/
if [ -z "$(command -v brew)" ]; then
    # Install Homebrew (It will append 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' to $HOME/.bashrc)
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if ! grep -q linuxbrew "$HOME"/.bashrc; then
        echo >> "$HOME"/.bashrc
        # shellcheck disable=SC2016
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME"/.bashrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        if [ -n "$(command -v apt-get)" ]; then sudo apt-get update && sudo apt-get install build-essential; fi
    fi
else
    brew update
fi

# Install AI tools
if [ -n "$(command -v brew)" ]; then
    if [ -z "$(command -v ollama)" ]; then
        brew install ollama
    elif [ "$(command -v ollama)" = "/home/linuxbrew/.linuxbrew/bin/ollama" ]; then
        brew upgrade ollama
    fi
fi

# Install Agent Skills
mkdir -p ~/.claude/skills ~/.copilot/skills ~/.config/opencode/skill ~/skills

if [ -d ~/skills/anthropics-skills ]; then
    cd ~/skills/anthropics-skills && git pull
else
    git clone https://github.com/anthropics/skills.git ~/skills/anthropics-skills
fi
ln -snf ~/skills/anthropics-skills/skills/skill-creator ~/.claude/skills/skill-creator

if [ -d ~/skills/planning-with-files ]; then
    cd ~/skills/planning-with-files && git pull
else
    git clone https://github.com/OthmanAdi/planning-with-files ~/skills/planning-with-files
fi
if [ -d ~/skills/planning-with-files/planning-with-files ]; then
    ln -snf ~/skills/planning-with-files/planning-with-files ~/.copilot/skills/planning-with-files
fi

if [ -d ~/skills/lp-api ]; then
    cd ~/skills/lp-api && git pull
else
    git clone https://github.com/fourdollars/lp-api.git ~/skills/lp-api
fi
if [ -d ~/skills/lp-api/launchpad ]; then
    ln -snf ~/skills/lp-api/launchpad ~/.claude/skills/launchpad
    if [ -n "$(command -v gemini)" ]; then
        if gemini extension list | grep launchpad; then
            cd ~/skills/lp-api/launchpad && gemini extensions uninstall launchpad && yes y | gemini extensions install . && cd -
        else
            cd ~/skills/lp-api/launchpad && yes y | gemini extensions install . && cd -
        fi
    fi
fi
