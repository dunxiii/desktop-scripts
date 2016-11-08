#!/bin/bash

# Create some default directories
mkdir ~/Bin
mkdir ~/Documents
mkdir ~/Downloads
mkdir ~/Insync
mkdir ~/Pictures
mkdir ~/Playground
mkdir ~/Public
mkdir -p ~/.vim/undodir

# Fetch dotfiles from github
git clone https://github.com/dunxiii/dotfiles.git ~/Git/dotfiles

# Switch git repo from https to ssh
cd ~/Git/dotfiles && git remote set-url origin git@github.com:dunxiii/dotfiles.git

# Deploy dotfiles
~/Git/dotfiles/install

# Install oh my zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
