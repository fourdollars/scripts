#!/usr/bin/env bash
# Strict bash mode
set -euo pipefail

# Ensure curl or wget is available
if [ -z "$(command -v curl)" ] && [ -z "$(command -v wget)" ]; then
    echo "Neither curl nor wget found. Attempting to install curl..."
    if [ -n "$(command -v apt-get)" ]; then
        sudo apt-get update && sudo apt-get install -y curl
    elif [ -n "$(command -v dnf)" ]; then
        sudo dnf install -y curl
    elif [ -n "$(command -v yum)" ]; then
        sudo yum install -y curl
    elif [ -n "$(command -v pacman)" ]; then
        sudo pacman -Sy --noconfirm curl
    else
        echo "Error: Cannot install curl. Please install curl or wget manually."
        exit 1
    fi
fi

# Helper function to download with curl or wget
download() {
    local url="$1"
    if [ -n "$(command -v curl)" ]; then
        curl -fsSL "$url"
    elif [ -n "$(command -v wget)" ]; then
        wget -qO- "$url"
    else
        echo "Error: Neither curl nor wget available"
        return 1
    fi
}

# bun is a fast, modern JavaScript runtime, compiler, and package manager - https://bun.sh
if [ -z "$(command -v bun)" ]; then
    # Install bun (It will append 'export BUN_INSTALL="$HOME/.bun"; export PATH="$BUN_INSTALL/bin:$PATH"' to $HOME/.bashrc)
    download https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
else
    download https://bun.sh/install | bash
fi

# Create node symlink to bun (required for copilot and other npm-based tools)
if [ ! -e "$HOME/.bun/bin/node" ] && [ -z "$(command -v node)" ]; then
    ln -sf "$HOME/.bun/bin/bun" "$HOME/.bun/bin/node"
fi

# Install AI tools
bun install -g opencode-ai opencode-lmstudio opencode-skills @github/copilot @google/gemini-cli @fission-ai/openspec

# uv is an extremely fast Python package and project manager, written in Rust - https://docs.astral.sh/uv/
if [ -z "$(command -v uv)" ]; then
    # Install uv (It will append '. "$HOME/.local/bin/env"' to $HOME/.bashrc and $HOME/.profile when PATH doesn't contain ~/.local/bin)
    download https://astral.sh/uv/install.sh | sh
    if ! grep -q "$HOME"/.local/bin <<<"$PATH"; then
        # shellcheck source=/dev/null
        source "$HOME"/.local/bin/env
    fi
else
    download https://astral.sh/uv/install.sh | sh
fi

# Install AI tools
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# Homebrew is a package manager for macOS/Linux - https://brew.sh/
if [ -z "$(command -v brew)" ]; then
    # Install Homebrew (It will append 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' to $HOME/.bashrc)
    /bin/bash -c "$(download https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
    if [ -z "$(command -v claude)" ]; then
        brew install --cask claude-code
    elif [ "$(command -v claude)" = "/home/linuxbrew/.linuxbrew/bin/claude" ]; then
        brew upgrade claude-code
    fi
fi

# Install Agent Skills
mkdir -p ~/.claude/skills ~/.copilot/skills ~/.config/opencode/skill ~/.gemini/skills ~/skills

if [ -d ~/skills/anthropics-skills ]; then
    cd ~/skills/anthropics-skills && git config pull.rebase true && git pull
else
    git clone https://github.com/anthropics/skills.git ~/skills/anthropics-skills
fi
ln -snf ~/skills/anthropics-skills/skills/skill-creator ~/.claude/skills/skill-creator
ln -snf ~/skills/anthropics-skills/skills/skill-creator ~/.gemini/skills/skill-creator

if [ -d ~/skills/planning-with-files ]; then
    cd ~/skills/planning-with-files && git pull
else
    git clone https://github.com/OthmanAdi/planning-with-files ~/skills/planning-with-files
fi
if [ -d ~/skills/planning-with-files/skills/planning-with-files ]; then
    ln -snf ~/skills/planning-with-files/skills/planning-with-files ~/.claude/skills/planning-with-files
    ln -snf ~/skills/planning-with-files/skills/planning-with-files ~/.gemini/skills/planning-with-files
fi

if [ -d ~/skills/lp-api ]; then
    cd ~/skills/lp-api && git config pull.rebase true && git pull
else
    git clone https://github.com/fourdollars/lp-api.git ~/skills/lp-api
fi
if [ -d ~/skills/lp-api/launchpad ]; then
    ln -snf ~/skills/lp-api/launchpad ~/.claude/skills/launchpad
    ln -snf ~/skills/lp-api/launchpad ~/.gemini/skills/launchpad
    if [ -n "$(command -v gemini)" ]; then
        if gemini extension list | grep launchpad; then
            cd ~/skills/lp-api/launchpad && gemini extensions uninstall launchpad && yes y | gemini extensions install . && cd -
        else
            cd ~/skills/lp-api/launchpad && yes y | gemini extensions install . && cd -
        fi
    fi
fi
ls -l ~/.claude/skills ~/.copilot/skills ~/.config/opencode/skill ~/.gemini/skills ~/skills
