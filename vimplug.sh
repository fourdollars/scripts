#!/bin/bash

if [ -f ~/.vim/autoload/plug.vim ]; then
	exit
fi

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cat >> ~/.vimrc <<ENDLINE
call plug#begin('~/.vim/plugged')
Plug 'mh21/errormarker.vim'
Plug 'sheerun/vim-polyglot'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'vim-scripts/EnhCommentify.vim'
Plug 'vim-scripts/OmniCppComplete'
Plug 'vim-scripts/gtk-vim-syntax'
Plug 'vim-scripts/taglist.vim'
Plug 'vim-syntastic/syntastic'
call plug#end()

" for mh21/errormarker.vim
let &errorformat="%f:%l:%c: %t%*[^:]:%m,%f:%l: %t%*[^:]:%m," . &errorformat
set makeprg=LANGUAGE=C\\ make

" for vim-syntastic/syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_sh_shellcheck_args = "-x"

" My own preferred settings
set hls
set expandtab
set shiftwidth=4
set tabstop=4

highlight Search ctermfg=white ctermbg=darkyellow

nmap <c-h> :set hls!<BAR>set hls?<CR>
nmap <c-l> :set list!<BAR>set list?<CR>
nmap <c-u> :set nu!<BAR>set nu?<CR>

" ctags plugin
nmap g+ viwy:tab ts <C-R>"<CR>
nmap g- viwy:pts <C-R>"<CR>
nmap g= viwy:sts <C-R>"<CR>
nmap g<Bar> viwy:vsplit<CR>:ts <C-R>"<CR>

" vimgrep for keyword
nmap g* :exec 'vimgrep /\\<'.expand('<cword>').'\\>/g **/*.[ch] **/*.[ch]pp **/*.cc **/*.java **/*.p[ly] **/*.rb **/*.vala **/*'<CR>

" quickfix
nmap <C-n> :cn<CR>
nmap <C-p> :cp<CR>

" taglist plugin
nnoremap <silent> <C-t> :TlistToggle<CR>
let Tlist_Use_Right_Window = 1
let Tlist_WinWidth = 50

set laststatus=2
set statusline=%4*%<\\ %1*[%F]
set statusline+=%4*\\ %5*[%{&fileencoding}, " encoding
set statusline+=%{&fileformat}]%m " file format
set statusline+=%4*%=\\ %6*%y%4*\\ %3*%l%4*,\\ %3*%c%4*\\ \\<\\ %2*%P%4*\\ \\>

function s:indent_folding()
    setlocal foldmethod=indent foldcolumn=4 foldnestmax=3 foldlevel=3
endfunction

function s:syntax_folding()
    setlocal foldmethod=syntax foldcolumn=4 foldnestmax=3 foldlevel=3
endfunction

if has("autocmd")
    autocmd BufReadPost * if line("'\\"") > 1 && line("'\\"") <= line("$") | exe "normal! g\`\\"" | endif
    autocmd FileType c,cpp  call s:syntax_folding()
    autocmd FileType sh,vim call s:indent_folding()
    filetype plugin indent on
endif
ENDLINE

vim +PlugInstall
