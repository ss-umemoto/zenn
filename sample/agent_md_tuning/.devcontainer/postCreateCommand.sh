mkdir "$HOME/.codex"
cp .codex/config.toml "$HOME/.codex/config.toml"

# Vibe Coding
npm install -g @openai/codex

# pre-commit
sudo apt-get update
sudo apt-get install -y pipx

pipx ensurepath
pipx install pre-commit

chmod +x .githooks/check-maintenance.sh
pre-commit install
pre-commit run --all-files