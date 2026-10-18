#!/usr/bin/env bash
# install-macos.sh — Homebrew toolchain. Run as your normal user.
set -euo pipefail

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  OK\033[0m %s\n' "$*"; }

command -v brew >/dev/null || { echo "Homebrew missing: https://brew.sh"; exit 1; }

step "homebrew update"
brew update

step "formulae (git, python, jdk, node, docker)"
brew install git python@3.12 openjdk@21 node@22 docker docker-compose colima
brew link --overwrite --force node@22 >/dev/null

step "jdk PATH"
JDK="$(brew --prefix openjdk@21)"
RC="$HOME/.zshrc"
grep -qF "$JDK/bin" "$RC" 2>/dev/null || echo "export PATH=\"$JDK/bin:\$PATH\"" >> "$RC"
export PATH="$JDK/bin:$PATH"
ok "$(java -version 2>&1 | head -1)"

step "GUI apps"
brew install --cask dotnet-sdk visual-studio-code bruno dbeaver-community

step "container runtime (colima, no Docker Desktop licence)"
if [ "${SKIP_CONTAINERS:-0}" = "1" ]; then
  ok "runtime start skipped (SKIP_CONTAINERS=1: no nested virtualisation)"
else
  colima status >/dev/null 2>&1 || colima start
  docker run --rm hello-world >/dev/null
  ok "docker works"
fi

step "verify"
for c in git python3.12 java javac node npm dotnet docker code; do
  printf '%-12s ' "$c"
  if command -v "$c" >/dev/null; then "$c" --version 2>&1 | head -1; else echo MISSING; fi
done

printf '\nOpen a new terminal (or source %s) before using java.\n' "$RC"
