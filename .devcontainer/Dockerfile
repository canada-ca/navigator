FROM elixir:1.18-slim

# Install packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    inotify-tools \
    ca-certificates \
    openssh-client \
    && apt-get clean

# Create the vscode user
RUN useradd -ms /bin/bash vscode

# Set vscode as the default user
USER vscode

# Install Hex, Rebar, and Phoenix
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new --force

