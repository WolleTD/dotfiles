#!/bin/bash
set -eu
DOTFILE_DIR=${0%/*}

if [[ $(pwd) != $HOME || $(realpath $DOTFILE_DIR) == $DOTFILE_DIR ]]; then
    echo "Call this script with relative path from \$HOME!"
    exit 1
fi

[[ -z ${XDG_CONFIG_HOME:-} ]] && XDG_CONFIG_HOME=$HOME/.config

[[ -x $(which tmux) ]] || (echo "Error: tmux not installed!" >&2; exit 1)

function install_omz_plugin() {
    local name=$1
    local src=$2

    if [[ ! -d "$omz_plugin_dir/$name" ]]; then
        echo "Downloading $name"
        git clone "$src" "$omz_plugin_dir/$name"
    else
        echo "Plugin $name already installed, updating"
        git -C "$omz_plugin_dir/$name" pull
    fi
}

function install_symlink() {
    local target=$1
    local name=$2

    if [[ -d "$name" ]]; then
        echo "$name is a directory, not linking!" >&2
    elif [[ -L "$name" && "$(readlink "$name")" == "$target" ]]; then
        echo "$name symlink already correct."
    elif ln -s "$target" "$name"; then
        echo "Created symlink $name -> $target"
    fi
}

echo "Updating oh-my-zsh submodule..."
git -C $DOTFILE_DIR submodule sync
git -C $DOTFILE_DIR submodule update --init

echo "Downloading oh-my-zsh plugins..."
omz_plugin_dir=$DOTFILE_DIR/oh-my-zsh/custom/plugins
install_omz_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git

install_symlink $DOTFILE_DIR/zshrc .zshrc
install_symlink $DOTFILE_DIR/vim/vimrc .vimrc
install_symlink $DOTFILE_DIR/vim/ideavimrc .ideavimrc
install_symlink $DOTFILE_DIR/tmux/tmux.conf .tmux.conf

mkdir -p $XDG_CONFIG_HOME/git
dotfile_dir_rel=$(realpath --relative-to=$XDG_CONFIG_HOME/git $DOTFILE_DIR)
install_symlink $dotfile_dir_rel/gitconfig $XDG_CONFIG_HOME/git/config

echo "Downloading tmux plugins..."
mkfifo /tmp/tmux_fifo
tmux new-session -d "$DOTFILE_DIR/tmux/plugins/tpm/bin/install_plugins > /tmp/tmux_fifo"
cat /tmp/tmux_fifo
rm /tmp/tmux_fifo

if [ ! -e .gitconfig ]; then
    echo "Create ~/.gitconfig so git config --global won't write to \$XDG_CONFIG_HOME/git/config"
    echo "# This file is system local. $XDG_CONFIG_HOME/git/config is symlinked to .dotfiles" > .gitconfig
else
    echo ".gitconfig already exists."
fi
