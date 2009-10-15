" MangleImageTag() - updates an <IMG>'s width and height tags.
"
" Requirements:
"       VIM 7 or later
"
" Copyright (C) 2004-2008 Christian J. Robinson <heptite@gmail.com>
"
" Based on "mangleImageTag" by Devin Weaver <ktohg@tritarget.com>
"
" This program is free software; you can  redistribute  it  and/or  modify  it
" under the terms of the GNU General Public License as published by  the  Free
" Software Foundation; either version 2 of the License, or  (at  your  option)
" any later version.
"
" This program is distributed in the hope that it will be useful, but  WITHOUT
" ANY WARRANTY; without  even  the  implied  warranty  of  MERCHANTABILITY  or
" FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General  Public  License  for
" more details.
"
" You should have received a copy of the GNU General Public License along with
" this program; if not, write to the Free Software Foundation, Inc., 59 Temple
" Place - Suite 330, Boston, MA 02111-1307, USA.
"
" RCS info: -------------------------------------------------------------- {{{
" $Id: MangleImageTag.vim,v 1.13 2009/06/23 14:04:35 infynity Exp $
" $Log: MangleImageTag.vim,v $
" Revision 1.13  2009/06/23 14:04:35  infynity
" *** empty log message ***
"
" Revision 1.12  2008/05/30 00:53:28  infynity
" - Clarify an error message
" - Don't move the cursor when updating the tag
"
" Revision 1.11  2008/05/26 01:11:25  infynity
" *** empty log message ***
"
" Revision 1.10  2008/05/01 05:01:02  infynity
" Code changed for Vim 7:
"  - Computed sizes should always be correct now
"  - Code is a bit cleaner, but unfortunately slower
"
" Revision 1.9  2007/05/04 02:03:42  infynity
" Computed sizes were very wrong when 'encoding' was set to UTF8 or similar
"
" Revision 1.8  2007/05/04 01:32:27  infynity
" Missing quotes
"
" Revision 1.7  2007/01/04 04:29:55  infynity
" Enclose the values of the width/height in quotes by default
"
" Revision 1.6  2006/09/22 06:25:14  infynity
" Search for the image file in the current directory and the buffer's directory.
"
" Revision 1.5  2006/06/09 07:56:08  infynity
" Was resetting 'autoindent' globally, switch it to locally.
"
" Revision 1.4  2006/06/08 04:16:17  infynity
" Temporarily reset 'autoindent' (required for Vim7)
"
" Revision 1.3  2005/05/19 18:31:31  infynity
" SizeGif was returning width as height and vice-versa.
"
" Revision 1.2  2004/03/22 10:04:24  infynity
" Update the right tag if more than one IMG tag appears on the line.
"
" Revision 1.1  2004/03/22 05:58:34  infynity
" Initial revision
" ------------------------------------------------------------------------ }}}

if v:version < 700 || exists("*MangleImageTag")
	finish
endif

function! MangleImageTag() "{{{1
	let start_linenr = line('.')
	let end_linenr = start_linenr
	let col = col('.') - 1
	let line = getline(start_linenr)

	if line !~? '<img'
		echohl ErrorMsg
		echomsg "The current line does not contain an image tag (see :help ;mi)."
		echohl None

		return
	endif

	" Get the rest of the tag if we have a partial tag:
	while line =~? '<img\_[^>]*$'
		let end_linenr = end_linenr + 1
		let line = line . "\n" . getline(end_linenr)
	endwhile

	" Make sure we modify the right tag if more than one is on the line:
	if line[col] != '<'
		let tmp = strpart(line, 0, col)
		let tagstart = strridx(tmp, '<')
	else
		let tagstart = col
	endif
	let savestart = strpart(line, 0, tagstart)
	let tag = strpart(line, tagstart)
	let tagend = stridx(tag, '>') + 1
	let saveend = strpart(tag, tagend)
	let tag = strpart(tag, 0, tagend)

	if tag[0] != '<' || col > strlen(savestart . tag) - 1
		echohl ErrorMsg
		echomsg "Cursor isn't on an IMG tag."
		echohl None

		return
	endif

	if tag =~? "src=\\(\".\\{-}\"\\|'.\\{-}\'\\)"
		let src = substitute(tag, ".\\{-}src=\\([\"']\\)\\(.\\{-}\\)\\1.*", '\2', '')
		if tag =~# 'src'
			let case = 0
		else
			let case = 1
		endif
	else
		echohl ErrorMsg
		echomsg "Image src not specified in the tag."
		echohl None

		return
	endif

	if ! filereadable(src)
		if filereadable(expand("%:p:h") . '/' . src)
			let src = expand("%:p:h") . '/' . src
		else
			echohl ErrorMsg
			echomsg "Can't find image file: " . src
			echohl None

			return
		endif
	endif

	let size = s:ImageSize(src)
	if len(size) != 2
		return
	endif

	if tag =~? "height=\\(\"\\d\\+\"\\|'\\d\\+\'\\|\\d\\+\\)"
		let tag = substitute(tag,
			\ "\\c\\(height=\\)\\([\"']\\=\\)\\(\\d\\+\\)\\(\\2\\)",
			\ '\1\2' . size[1] . '\4', '')
	else
		let tag = substitute(tag,
			\ "\\csrc=\\([\"']\\)\\(.\\{-}\\|.\\{-}\\)\\1",
			\ '\0 ' . (case ? 'HEIGHT' : 'height') . '="' . size[1] . '"', '')
	endif

	if tag =~? "width=\\(\"\\d\\+\"\\|'\\d\\+\'\\|\\d\\+\\)"
		let tag = substitute(tag,
			\ "\\c\\(width=\\)\\([\"']\\=\\)\\(\\d\\+\\)\\(\\2\\)",
			\ '\1\2' . size[0] . '\4', '')
	else
		let tag = substitute(tag,
			\ "\\csrc=\\([\"']\\)\\(.\\{-}\\|.\\{-}\\)\\1",
			\ '\0 ' . (case ? 'WIDTH' : 'width') . '="' . size[0] . '"', '')
	endif

	let line = savestart . tag . saveend

	let saveautoindent=&autoindent
	let &l:autoindent=0

	call setline(start_linenr, split(line, "\n"))

	let &l:autoindent=saveautoindent
endfunction

function! s:ImageSize(image) "{{{1
	let ext = fnamemodify(a:image, ':e')

	if ext !~? 'png\|gif\|jpe\?g'
		echohl ErrorMsg
		echomsg "Image type not recognized: " . tolower(ext)
		echohl None

		return
	endif

	if filereadable(a:image)
		let ldsave=&lazyredraw
		set lazyredraw

		let buf=readfile(a:image, 'b', 1024)
		let buf2=[]

		let i=0
		for l in buf
			let string = split(l, '\zs')
			for c in string
				let char = char2nr(c)
				call add(buf2, (char == 10 ? '0' : char))

				" Keep the script from being too slow, but could cause a JPG
				" (and GIF/PNG?) to return as "malformed":
				let i+=1
				if i > 1024 * 4
					break
				endif
			endfor
			call add(buf2, '10')
		endfor

		if ext ==? 'png'
			let size = s:SizePng(buf2)
		elseif ext ==? 'gif'
			let size = s:SizeGif(buf2)
		elseif ext ==? 'jpg' || ext ==? 'jpeg'
			let size = s:SizeJpg(buf2)
		endif
	else
		echohl ErrorMsg
		echomsg "Can't read file: " . a:image
		echohl None

		return
	endif

	return size
endfunction

function! s:SizeGif(lines) "{{{1
	let i=0
	let len=len(a:lines)
	while i <= len
		if join(a:lines[i : i+9], ' ') =~ '^71 73 70\( \d\+\)\{7}'
			let width=s:Vec(reverse(a:lines[i+6 : i+7]))
			let height=s:Vec(reverse(a:lines[i+8 : i+9]))

			return [width, height]
		endif
		let i+=1
	endwhile

	echohl ErrorMsg
	echomsg "Malformed GIF file."
	echohl None

	return
endfunction

function! s:SizeJpg(lines) "{{{1
	let i=0
	let len=len(a:lines)
	while i <= len
		if join(a:lines[i : i+8], ' ') =~ '^255 192\( \d\+\)\{7}'
			let height = s:Vec(a:lines[i+5 : i+6])
			let width = s:Vec(a:lines[i+7 : i+8])

			return [width, height]
		endif
		let i+=1
	endwhile

	echohl ErrorMsg
	echomsg "Malformed JPEG file."
	echohl None

	return
endfunction

function! s:SizePng(lines) "{{{1
	let i=0
	let len=len(a:lines)
	while i <= len
		if join(a:lines[i : i+11], ' ') =~ '^73 72 68 82\( \d\+\)\{8}'
			let width = s:Vec(a:lines[i+4 : i+7])
			let height = s:Vec(a:lines[i+8 : i+11])

			return [width, height]
		endif
		let i+=1
	endwhile

	echohl ErrorMsg
	echomsg "Malformed PNG file."
	echohl None

	return
endfunction

function! s:Vec(nums) "{{{1
	let n = 0
	for i in a:nums
		let n = n * 256 + i
	endfor
	return n
endfunction

" vim:ts=4:sw=4:
" vim600:fdm=marker:fdc=2:cms=\ \"%s:
