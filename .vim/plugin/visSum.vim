" vim:ft=vim foldmethod=marker tw=78
" ==========================================================================
" File:         visSum.vim (global plugin)
" Last Changed: 2007-11-01
" Maintainer:   Erik Falor <ewfalor@gmail.com>
" Version:      0.3
" License:      Vim License
" ==========================================================================

" Exit quickly if the script has already been loaded
let s:this_version = '0.3'
if exists('g:loaded_visSum') && g:loaded_visSum == s:this_version
	finish
endif
let g:loaded_visSum = s:this_version

"Mappings {{{
" clean up existing key mappings upon re-loading of script
if hasmapto('<Plug>SumNum')
	nunmap \su
	vunmap \su
	nunmap <Plug>SumNum
	vunmap <Plug>SumNum
endif

" Key mappings
nmap <silent> <unique> <Leader>su <Plug>SumNum
vmap <silent> <unique> <Leader>su <Plug>SumNum

" Plug mappings for the key mappings
nmap <silent> <unique> <script> <Plug>SumNum	:call <SID>SumNumbers() <CR>
vmap <silent> <unique> <script> <Plug>SumNum	:call <SID>SumNumbers() <CR>

" Command
command! -nargs=? -range -register VisSum call <SID>SumNumbers("<reg>")
"}}}

function! <SID>SumNumbers(...) range  "{{{
	let l:sum = 0
	let l:cur = 0

	if visualmode() =~ '\cv'  
		let y1      = line("'<")
		let y2      = line("'>")
		while y1 <= y2
			let l:cur = matchstr( getline(y1), '-\{-}\d\+' )
			let l:sum += l:cur
			let y1 += 1
		endwhile
	elseif visualmode() == "\<c-v>"
		let y1      = line("'<")
		let y2      = line("'>")
		let x1		= col("'<") - 1
		let len		= col("'>") - x1
		while y1 <= y2
			let line = getline(y1)
			let chunk = strpart(line, x1, len)
			let l:cur = matchstr( strpart(getline(y1), x1, len ), '-\{-}\d\+' )
			let l:sum += l:cur
			let y1 += 1
		endwhile
	else
		echoerr "You must select some text in visual mode first"
		return
	endif
	redraw | echomsg "sum = " . l:sum 
	"save the sum in the variable b:sum, and optionally
	"into the register specified by the user
	let b:sum = l:sum
	if a:0 == 1 && len(a:1) > 0
		execute "let @" . a:1 . " = b:sum"
	endif
endfunction "}}}

"Test Data "{{{
" <column width=\"24\"> The winter of '49</column>
" <column width=\"18\"> The Summer of '48</column>
" <column width=\"44\"/>123
" <column width=\"14\"/>123
"1                      123
"2                      123
"-3                     123
"-4                     123
"5                      123
"6
"7
"8
"8 
"9 
"10
"11
"12
"13
"14
"15
"16
"17
"}}}
