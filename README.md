# $4's little scripts collection

## ai-env.sh

 A setup script to install, update, and configure AI runtimes, CLI tools, coding agents, and agent skills across multiple environments.

```bash
$ ./ai-env.sh
```

### Features

- **AI CLI Tools & Agents:**
  - **Antigravity:** `agy` CLI
  - **Bun:** `@fission-ai/openspec`, `@github/copilot`, `@google/gemini-cli`, `@opencode/cli`
  - **Homebrew / Native:** `claude` (Claude Code), `codex`, `herdr`, `ollama`
  - **uv:** `specify-cli` ([spec-kit](https://github.com/github/spec-kit))
- **Agent Skills Integration:**
  - Automatically sets up and symlinks skills for Antigravity CLI (`~/.gemini/antigravity-cli/skills`), Claude Code (`~/.claude/skills`), Gemini CLI (`~/.gemini/skills`), GitHub Copilot (`~/.copilot/skills`), and OpenCode (`~/.config/opencode/skill`).
  - Included skills: `herdr`, `launchpad` (`lp-api` extension), `skill-creator` (Anthropic), and `superpowers`.
- **Runtimes & Package Managers:**
  - [bun](https://bun.sh) (with Node.js compatibility symlink)
  - [Homebrew](https://brew.sh/)
  - [uv](https://docs.astral.sh/uv/) (fast Python package manager)

## launchpad-api.sh

 A script to access [Launchpad API](https://api.launchpad.net/).

> Usage: ./launchpad-api.sh [get|post] API_URL [param1==value1|field1=value1]... # Check the REQUEST_ITEM part in the httpie manual for details.

```
./launchpad-api.sh get people/+me        # Get your own information.
./launchpad-api.sh get bugs/1            # Get the info of bug 1.
./launchpad-api.sh get bugs/1/bug_tasks  # Get the tasks of bug 1.
```

## mainline-kernels.sh

 Install the mainline kernels from https://kernel.ubuntu.com/~kernel-ppa/mainline on Ubuntu.

```
$ ./mainline-kernels.sh -h
Usage:
    ./mainline_kernels.sh [options] [versions] ...

Options:
    -h|--help          The manual of this script
    -d|--download-only Download only and not install
    -f|--from NUM      Lower bound of kernel version
    -t|--to   NUM      Upper bound of kernel version
    -l|--list          List available kernel versions
    -r|--remove        Remove mainline kernels
    -u|--update        Update the script itself
```

 https://bit.ly/mainline_kernels

## mkfreedos.sh

 A quick script to make FreeDOS USB stick on Debian/Ubuntu.

> Usage: ./mkfreedos.sh [device node, such as /dev/sdb] [Label Name]

## run-autopkgtest.sh

 A general purpose autopkgtest wrapper that can set up the testbed and run tests on the testbed.

```
$ ./run-autopkgtest.sh -h
Name:

 run-autopkgtest.sh is a general purpose autopkgtest wrapper that can set up the testbed and run tests on the testbed.

Usage:

 run-autopkgtest.sh [lxc|qemu|vm-ubuntu-cloud] [OPTIONS] {focal,unstable,...}

OPTIONS:

 -h | --help
    Print help manual

 -A | --architecture
    Specify the architecture such as amd64, arm64, ...

 -B | --benchmark
    Measure the time in each major process

 -C | --credentials
    Detect and execute the environment setup script of credentials.

 -d | --debug
    Enable debug mode.

 -F | --flush-cache
    Remove the existing testbed and build a new one.

 -m | --mirror
    Specify the mirror site. Now it only works for qemu testbed.

 -R | --rebuild-testbed
    Rebuild the testbed

 -S | --shell-fail
    Run an interactive shell in the testbed after a failed build, test, or dependency installation.

 -s | --size
    Specify the image size for qemu. It is '12G' by default.

 -t | --test-name
    Run only the given test name (from test control file).
```

 https://git.io/run-autopkgtest

## vimplug.sh

 A quick script to setup the vim environment.

```
wget https://bit.ly/vimplug -O - | bash -
```
 https://bit.ly/vimplug

> Please backup your own ~/.vimrc before using this script.
