#!/bin/bash

if [ -f ~/.vim/autoload/plug.vim ]; then
	exit
fi

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cat >> ~/.vimrc <<ENDLINE
call plug#begin('~/.vim/plugged')
Plug 'sheerun/vim-polyglot'
call plug#end()
ENDLINE

vim +PlugInstall
