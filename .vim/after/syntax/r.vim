
" New line, carriage return, tab, bell, feed, backslash
syn match rSpecial display contained "\\\(n\|r\|t\|a\|f\|'\|\"\)\|\\\\"

" Hexadecimal and Octal digits
syn match rSpecial display contained "\\\(x\x\{1,2}\|\o\{1,3}\)"

syn keyword rBoolean  T F
syn keyword rConstant R.version.string
syn match rComment contains=@Spell /\#.*/
syn region rString contains=rSpecial,@Spell start=/"/ skip=/\\\\\|\\"/ end=/"/
syn region rString contains=rSpecial,@Spell start=/'/ skip=/\\\\\|\\'/ end=/'/
let rfunfile = system("echo -n $HOME") . "/.vim/tools/rfunctions"
if filereadable(rfunfile)
  source ~/.vim/tools/rfunctions
endif

hi def link rSpecial SpecialChar
hi def link rFunction Function

"
" Mac OS: send selected lines to the running R application.
" 
" Send the selected text to R.
function! RCode() range
    " sending selected lines to interactive R application
    let cmd = join(getline(a:firstline,a:lastline),"\\n")
    let cmd = substitute(cmd,"\"","\\\\\"","g")
    let cmd = substitute(cmd,"\'","\\\\\"","g")
    call system("osascript -e 'tell application \"R\" to cmd \"" . cmd . "\"'")
endfunction

" Source the current file in R.
function! RSource()
    let file = getcwd() . "/" . bufname("%")
    call system("osascript -e 'tell application \"R\" to cmd \"source(\\\"" . file . "\\\")\"'")
endfunction

nmap <buffer> <F3>      :call RCode()<CR><CR>
vmap <buffer> <F3>      :call RCode()<CR><CR>
imap <buffer> <F3> <ESC>:call RCode()<CR><CR>a

nmap <buffer> <F4>      :call RSource()<CR>
imap <buffer> <F4> <ESC>:call RSource()<CR>gi
