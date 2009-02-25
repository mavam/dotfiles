scriptencoding utf-8

" {{{ Vim Look
colorscheme koehler
set background=dark     " syntax highlighting for a dark terminal background
set ruler               " Show the cursor position all the time
"set statusline=%<%F%h%m%r%h%w%y\ %{strftime(\"%c\",getftime(expand(\"%:p\")))}% =\ lin:%l\,%L\ col:%c%V\ pos:%o\ ascii:%b\ %P
" }}}

" {{{ General settings
set autoindent          " Copy indent from current line when starting a new line
set backspace=2         " Allow backspacing over everything in insert mode
set history=200         " lines of command history
set ignorecase          " Case-insensitive search
set smartcase           " Override ignorecase when searching uppercase
set incsearch           " jumps to search word as you type 
set nocompatible        " Use Vim defaults
set modeline            " modelines at the {end,beginning} of a file are handy!

" low priority for these files in tab-completion
set suffixes+=.aux,.bbl,.blg,.dvi,.log,.pdf     " LaTeX
set suffixes+=.info,.out,.o,.lo

" When displaying line numbers, don't use an annoyingly wide number column. This
" doesn't enable line numbers -- :set number will do that. The value given is a
" minimum width to use for the number column, not a fixed size.
if v:version >= 700
  set numberwidth=3
endif

set viminfo='20,\"500   " Keep a .viminfo file.
" }}}

" {{{ Formatting settings
"set formatoptions=croql
set formatoptions=tcrqn " see :h 'fo-table for a detailed explanation

set copyindent          " Copy the structure of existing indentation
set shiftwidth=4        " tab indention 
set tabstop=4           " number of spcaes for a tab
set textwidth=80        " textwidth
set expandtab           " expand tabs to spaces

" Indentation Tweaks.
" e-s = do not indent if opening bracket is not first character in a line.
" g0  = do not indent C++ scope declarations.
" t0  = do not indent a function's return type declaration.
set cino=e-s,g0,t0
" }}}

"{{{ Spell settings
if v:version >= 700
  set spelllang=en,de
  set spellfile=~/.vim/spellfile.add
endif

highlight clear SpellBad
highlight SpellBad term=standout ctermfg=1 term=underline cterm=underline
highlight clear SpellCap
highlight SpellCap term=underline cterm=underline
highlight clear SpellRare
highlight SpellRare term=underline cterm=underline
highlight clear SpellLocal
highlight SpellLocal term=underline cterm=underline
"}}}

" {{{ Key bindings

" Function keys
"===============
" F1: Toggle hlsearch (highlight search matches).
nmap <F1> :set hls!<CR>

" F2: Toggle list (display unprintable characters).
nnoremap <F2> :set list!<CR>

" F3: Toggle expansion of tabs to spaces.
" nmap <F3> :set expandtab!<CR>

" F4: Toggle past mode.
set pastetoggle=<F4>

" Allow deletion without updating the clipboard (yank buffer)
vnoremap x "_x
vnoremap X "_X

" Using 'gj' and 'gk' instead of just 'j' and 'k' to move down and up by screen
" lines instead of file lines. The following mapping does the same when holding
" down the ALT key.
"noremap <Up> gk
"noremap! <Up> <C-O>gk
"noremap <Down> gj
"noremap! <Down> <C-O>gj
"noremap! <M-Up> <Up>
"noremap! <M-Down> <Down>
"noremap! <M-Up> k
"noremap! <M-Down> j


" }}}

" {{{ Folding settings
if version >= 600
    set foldenable
    set foldmethod=marker
endif
" }}}

" {{{ Locale settings
" If we have a BOM, always honour that rather than trying to guess.
if &fileencodings !~? "ucs-bom"
  set fileencodings^=ucs-bom
endif

" Always check for UTF-8 when trying to determine encodings.
if &fileencodings !~? "utf-8"
  set fileencodings+=utf-8
endif

" Make sure we have a sane fallback for encoding detection
set fileencodings+=default
" }}}

" {{{ Syntax highlighting settings
" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif
" }}}

" {{{ Filetype plugin settings
" Enable plugin-provided filetype settings, but only if the ftplugin
" directory exists (which it won't on livecds, for example).
if isdirectory(expand("$VIMRUNTIME/ftplugin"))
  filetype plugin on
  filetype indent on
  set grepprg=grep\ -nH\ $*
endif

" Prevents Vim 7.0 from setting filetype to 'plaintex'
let g:tex_flavor='latex'

let g:html_tag_case = 'lowercase'

" }}}

" {{{ Custom functions
function! s:DiffWithSaved() 
  let filetype=&ft 
  diffthis 
  " new | r # | normal 1Gdd - for horizontal split 
  vnew | r # | normal 1Gdd 
  diffthis 
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype 
endfunction 
com! Diff call s:DiffWithSaved() 

" advanced incrementing
" example :let I=223  :'a,'bs/^/\=INC(5)/
let g:I=0
function! INC(increment)
    let g:I =g:I + a:increment
    return g:I
endfunction
" }}}

" {{{ Sourced files
source ~/.vim/filetypes.vim
" }}}

" vim: set fenc=utf-8 tw=80 sw=2 sts=2 et foldmethod=marker :
