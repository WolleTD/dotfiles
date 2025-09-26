#!/bin/bash
DOTFILE_DIR=${0%/*}

if [[ $(pwd) != $HOME || $(realpath $DOTFILE_DIR) == $DOTFILE_DIR ]]; then
    echo "Call this script with relative path from \$HOME!"
    exit 1
fi

if [[ -f $HOME/.tmux.conf || -f $HOME/.vimrc || -f $HOME/.zshrc \
    || -f $HOME/.tmux || -f $HOME/.vim ]]; then
    echo "Files exist, aborting!"
    exit 1
fi

[[ -z $XDG_CONFIG_HOME ]] && XDG_CONFIG_HOME=$HOME/.config

[[ -x $(which tmux) ]] || (echo "Error: tmux not installed!" >&2; exit 1)

echo "Updating submodules..."
pushd $DOTFILE_DIR
git submodule sync
git submodule update --init
popd

echo "Linking .tmux.conf"
ln -s $DOTFILE_DIR/tmux/tmux.conf .tmux.conf
echo "Downloading tmux plugins..."
tmux new-session -d sh -c "$DOTFILE_DIR/tmux/plugins/tpm/bin/install_plugins|tee /tmp/dotfiles.log"
cat /tmp/dotfiles.log
echo "Linking .zshrc"
ln -s $DOTFILE_DIR/zshrc .zshrc
echo "Linking .vimrc"
ln -s $DOTFILE_DIR/vim/vimrc .vimrc
ln -s $DOTFILE_DIR/vim/ideavimrc .ideavimrc
echo "Linking $XDG_CONFIG_HOME/git/config"
mkdir -p $XDG_CONFIG_HOME/git
ln -s $(realpath --relative-to=$XDG_CONFIG_HOME/git $DOTFILE_DIR)/gitconfig \
    $XDG_CONFIG_HOME/git/config
# Create ~/.gitconfig so git config --global won't write to $XDG...
touch $HOME/.gitconfig
echo "Set global git excludesfile in ~/.gitignore"
git config --global core.excludesfile $(realpath $DOTFILE_DIR)/global-gitignore
