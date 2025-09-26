#!/bin/bash
DOTFILE_DIR=${0%/*}

if [[ $(pwd) != $HOME || $(realpath $DOTFILE_DIR) == $DOTFILE_DIR ]]; then
    echo "Call this script with relative path from \$HOME!"
    exit 1
fi

[[ -z $XDG_CONFIG_HOME ]] && XDG_CONFIG_HOME=$HOME/.config

[[ -x $(which tmux) ]] || (echo "Error: tmux not installed!" >&2; exit 1)

echo "Updating submodules..."
pushd $DOTFILE_DIR >/dev/null
git submodule sync
git submodule update --init
popd >/dev/null

function symlink() {
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

symlink $DOTFILE_DIR/zshrc .zshrc
symlink $DOTFILE_DIR/vim/vimrc .vimrc
symlink $DOTFILE_DIR/vim/ideavimrc .ideavimrc
symlink $DOTFILE_DIR/tmux/tmux.conf .tmux.conf

mkdir -p $XDG_CONFIG_HOME/git
dotfile_dir_rel=$(realpath --relative-to=$XDG_CONFIG_HOME/git $DOTFILE_DIR)
symlink $dotfile_dir_rel/gitconfig $XDG_CONFIG_HOME/git/config

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
