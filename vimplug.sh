#!/bin/bash

if [ ! -f ~/.vim/autoload/plug.vim ]; then
    if command -v curl >/dev/null 2>&1; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    elif command -v wget >/dev/null 2>&1; then
        [ ! -d ~/.vim/autoload ] && mkdir -p ~/.vim/autoload
        wget https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -O ~/.vim/autoload/plug.vim
    else
        echo "There is no wget or curl to download https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        exit 1
    fi
fi

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "Please install shellcheck."
fi

if ! command -v ctags >/dev/null 2>&1; then
    echo "Please install ctags."
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Please install git."
    exit 1
fi

cat > ~/.vimrc <<ENDLINE
call plug#begin('~/.vim/plugged')
Plug 'mh21/errormarker.vim'
Plug 'sheerun/vim-polyglot'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'vim-scripts/EnhCommentify.vim'
Plug 'vim-scripts/OmniCppComplete'
Plug 'vim-scripts/gtk-vim-syntax'
Plug 'vim-scripts/taglist.vim'
Plug 'vim-syntastic/syntastic'
Plug 'tpope/vim-unimpaired'
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
let g:syntastic_python_checkers = ['pep8']

" My own preferred settings
set expandtab
set hlsearch
set number
set shiftwidth=4
set tabstop=4

highlight LineNr ctermfg=grey
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
    autocmd FileType sh,vim,python call s:indent_folding()
    filetype plugin indent on
endif
ENDLINE

vim +PlugInstall

if command -v stty >/dev/null 2>&1; then
    stty sane
fi
