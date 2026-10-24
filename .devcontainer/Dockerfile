FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/

# Put mise shims on PATH for every session (interactive or not, including
# `devpod ssh --command`, IDE tasks and scripts). Interactive shells also run
# `mise activate` from the chezmoi dotfiles.
ENV PATH=/home/vscode/.local/share/mise/shims:$PATH
