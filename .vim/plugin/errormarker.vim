" ============================================================================
"    Copyright: Copyright (C) 2007 Michael Hofmann
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               errormarker.vim is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. In no
"               event will the copyright holder be liable for any damages
"               resulting from the use of this software.
" Name Of File: errormarker.vim
"  Description: Sets markers for compile errors
"   Maintainer: Michael Hofmann (mh21 at piware dot de)
"      Version: See g:loaded_errormarker for version number.
"        Usage: Normally, this file should reside in the plugins
"               directory and be automatically sourced. If not, you must
"               manually source this file using ':source errormarker.vim'.

" === Support for automatic retrieval (Vim script 642) ==================={{{1

" GetLatestVimScripts: 1861 1 :AutoInstall: errormarker.vim

" === Initialization ====================================================={{{1

" Exit when the Vim version is too old or missing some features
if v:version < 700 || !has ("signs") || !has ("autocmd")
    finish
endif

" Exit quickly when the script has already been loaded or when 'compatible'
" is set.
if exists("g:loaded_errormarker") || &compatible
    finish
endif

" Version number.
let g:loaded_errormarker = "0.1.11"

let s:save_cpo = &cpo
set cpo&vim

function! s:DefineVariable (name, default)
    if !exists (a:name)
        execute 'let ' . a:name . ' = "' . escape (a:default, '\"') . '"'
    endif
endfunction

" === Variables =========================================================={{{1

" Defines the icon to show for errors in the gui
call s:DefineVariable ("g:errormarker_erroricon",
            \ has('win32') ? expand ("~/vimfiles/icons/error.bmp") :
                \ "/usr/share/icons/gnome/16x16/status/dialog-error.png")

" Defines the icon to show for warnings in the gui
call s:DefineVariable ("g:errormarker_warningicon",
            \ has('win32') ? expand ("~/vimfiles/icons/warning.bmp") :
                \ "/usr/share/icons/gnome/16x16/status/dialog-warning.png")

" Defines the text (two characters) to show for errors in the gui
call s:DefineVariable ("g:errormarker_errortext", "EE")

" Defines the text (two characters) to show for warnings in the gui
call s:DefineVariable ("g:errormarker_warningtext", "WW")

" Defines the highlighting group to use for errors in the gui
call s:DefineVariable ("g:errormarker_errorgroup", "Todo")

" Defines the highlighting group to use for warnings in the gui
call s:DefineVariable ("g:errormarker_warninggroup", "Todo")

" Defines the error types that should be treated as warning
call s:DefineVariable ("g:errormarker_warningtypes", "wW")

" === Global ============================================================={{{1

" Define the signs
let s:erroricon = ""
if filereadable (g:errormarker_erroricon)
    let s:erroricon = " icon=" . escape (g:errormarker_erroricon, '| \')
endif
let s:warningicon = ""
if filereadable (g:errormarker_warningicon)
    let s:warningicon = " icon=" . escape (g:errormarker_warningicon, '| \')
endif
execute "sign define errormarker_error text=" . g:errormarker_errortext .
            \ " linehl=" . g:errormarker_errorgroup . s:erroricon

execute "sign define errormarker_warning text=" . g:errormarker_warningtext .
            \ " linehl=" . g:errormarker_warninggroup . s:warningicon

" Setup the autocommands that handle the MRUList and other stuff.
augroup errormarker
    autocmd QuickFixCmdPost make call <SID>SetErrorMarkers()
augroup END

" === Functions =========================================================={{{1

function! s:SetErrorMarkers()
    if has ('balloon_eval')
        let &balloonexpr = "<SNR>" . s:SID() . "_ErrorMessageBalloons()"
        set ballooneval
    endif

    sign unplace *

    let l:positions = {}
    for l:d in getqflist()
        if (l:d.bufnr == 0 || l:d.lnum == 0)
            continue
        endif

        let l:key = l:d.bufnr . l:d.lnum
        if has_key (l:positions, l:key)
            continue
        endif
        let l:positions[l:key] = 1

        if strlen (l:d.type) &&
                    \ stridx (g:errormarker_warningtypes, l:d.type) >= 0
            let l:name = "errormarker_warning"
        else
            let l:name = "errormarker_error"
        endif
        execute ":sign place " . l:key . " line=" . l:d.lnum . " name=" .
                    \ l:name . " buffer=" . l:d.bufnr
    endfor
endfunction

function! s:ErrorMessageBalloons()
    for l:d in getqflist()
        if (d.bufnr == v:beval_bufnr && d.lnum == v:beval_lnum)
            return l:d.text
        endif
    endfor
    return ""
endfunction

function! s:SID()
    return matchstr (expand ('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

" === Help file installation ============================================={{{1

" Original version: Copyright (C) Mathieu Clabaut, author of vimspell
" http://www.vim.org/scripts/script.php?script_id=465
function! s:InstallDocumentation(full_name, revision)
    " Name of the document path based on the system we use:
    if has("vms")
        " No chance that this script will work with
        " VMS -  to much pathname juggling here.
        return 1
    elseif (has("unix"))
        " On UNIX like system, using forward slash:
        let l:slash_char = '/'
        let l:mkdir_cmd  = ':silent !mkdir -p '
    else
        " On M$ system, use backslash. Also mkdir syntax is different.
        " This should only work on W2K and up.
        let l:slash_char = '\'
        let l:mkdir_cmd  = ':silent !mkdir '
    endif

    let l:doc_path = l:slash_char . 'doc'
    let l:doc_home = l:slash_char . '.vim' . l:slash_char . 'doc'

    " Figure out document path based on full name of this script:
    let l:vim_plugin_path = fnamemodify(a:full_name, ':h')
    let l:vim_doc_path    = fnamemodify(a:full_name, ':h:h') . l:doc_path
    if (!(filewritable(l:vim_doc_path) == 2))
        echo "Creating doc path: " . l:vim_doc_path
        execute l:mkdir_cmd . '"' . l:vim_doc_path . '"'
        if (!(filewritable(l:vim_doc_path) == 2))
            " Try a default configuration in user home:
            let l:vim_doc_path = expand("~") . l:doc_home
            if (!(filewritable(l:vim_doc_path) == 2))
                execute l:mkdir_cmd . '"' . l:vim_doc_path . '"'
                if (!(filewritable(l:vim_doc_path) == 2))
                    echohl WarningMsg
                    echo "Unable to create documentation directory.\ntype :help add-local-help for more information."
                    echohl None
                    return 0
                endif
            endif
        endif
    endif

    " Exit if we have problem to access the document directory:
    if (!isdirectory(l:vim_plugin_path) || !isdirectory(l:vim_doc_path) || filewritable(l:vim_doc_path) != 2)
        return 0
    endif

    " Full name of script and documentation file:
    let l:script_name = fnamemodify(a:full_name, ':t')
    let l:doc_name    = fnamemodify(a:full_name, ':t:r') . '.txt'
    let l:plugin_file = l:vim_plugin_path . l:slash_char . l:script_name
    let l:doc_file    = l:vim_doc_path    . l:slash_char . l:doc_name

    " Bail out if document file is still up to date:
    if (filereadable(l:doc_file) && getftime(l:plugin_file) < getftime(l:doc_file))
        return 0
    endif

    " Prepare window position restoring command:
    if (strlen(@%))
        let l:go_back = 'b ' . bufnr("%")
    else
        let l:go_back = 'enew!'
    endif

    " Create a new buffer & read in the plugin file (me):
    setl nomodeline
    exe 'enew!'
    silent exe 'r ' . l:plugin_file

    setl modeline
    let l:buf = bufnr("%")
    setl noswapfile modifiable

    norm zR
    norm gg

    " Delete from first line to a line starts with
    " === START_DOC
    silent 1,/^=\{3,}\s\+START_DOC\C/ d

    " Delete from a line starts with
    " === END_DOC
    " to the end of the documents:
    silent /^=\{3,}\s\+END_DOC\C/,$ d

    " Add modeline for help doc: the modeline string is mangled intentionally
    " to avoid it be recognized by Vim:
    call append(line('$'), '')
    call append(line('$'), ' v' . 'im:tw=78:ts=8:ft=help:norl:')

    " Replace revision:
    silent exe "normal :1s/#version#/ v" . a:revision . "/\<CR>"

    " Save the help document:
    silent exe 'w! ' . l:doc_file
    exe l:go_back
    exe 'bw ' . l:buf

    " Build help tags:
    exe 'helptags ' . l:vim_doc_path

    return 1
endfunction

call s:InstallDocumentation(expand('<sfile>:p'), g:loaded_errormarker)

" === Cleanup ============================================================{{{1

let &cpo = s:save_cpo

finish

" === Help file =========================================================={{{1
=== START_DOC
*errormarker*   Plugin to highlight error positions #version#

                        ERROR MARKER REFERENCE MANUAL ~

1. Usage                                                   |errormarker-usage|
2. Customization                                   |errormarker-customization|
3. Credits                                               |errormarker-credits|
4. Changelog                                           |errormarker-changelog|

This plugin is only available if Vim was compiled with the |+signs| feature
and 'compatible' is not set.

==============================================================================
1. USAGE                                                   *errormarker-usage*

This plugin hooks the quickfix command |QuickFixCmdPost| and generates error
markers for every line that contains an error. Vim has to be compiled with
|+signs| for this to work.

Additionally, a tooltip with the error message is shown when you hover with
the mouse over a line with an error (only available when compiled with the
|+balloon_eval| feature).

The functionality mentioned here is a plugin, see |add-plugin|. This plugin is
only available if 'compatible' is not set and Vim was compiled with |+signs|
support. You can avoid loading this plugin by setting the "loaded_errormarker"
variable in your |vimrc| file: >
        :let loaded_errormarker = 1

==============================================================================
2. CUSTOMIZATION                                   *errormarker-customization*

You can customize the signs that are used by Vim to mark warnings and errors
(see |:sign-define| for details).

                             *errormarker_erroricon* *errormarker_warningicon*
The icons that are used for the warnings and error signs in the GUI version of
Vim can be set by >
        :let errormarker_erroricon = "/path/to/error/icon/name.png"
        :let errormarker_warningicon = "/path/to/warning/icon/name.png"
If an icon is not found, text-only markers are displayed instead. The bitmap
should fit into the place of two characters.

You must use full paths for these variables, for icons in your home directory
expand the paths in your .vimrc with something like >
        :let errormarker_erroricon = expand ("~/.vim/icons/error.png")
To get working icons on Microsoft Windows, place icons for errors and warnings
(you can use Google at http://images.google.com/images?q=error&imgsz=icon to
find some nice ones) as error.bmp and warning.bmp in your home directory at
C:\Documents and Settings\<user>\vimfiles\icons.

                             *errormarker_errortext* *errormarker_warningtext*
The text that is displayed without a GUI or if the icon files can not be found
can be set by >
        :let errormarker_errortext = "Er"
        :let errormarker_warningtext = "Wa"
The maximum length is two characters.

                           *errormarker_errorgroup* *errormarker_warninggroup*
The hightlighting groups that are used to mark the lines that contain warnings
and errors can be set by >
        :let errormarker_errorgroup = "ErrorMsg"
        :let errormarker_warninggroup = "Todo"
<
                                                    *errormarker_warningtypes*
If the compiler reports a severity for the error messages this can be used to
distinguish between warnings and errors. Vim uses a single character error
type that can be parsed with |errorformat| (%t). The error types that should
be treated as warnings can be set by >
        let errormarker_warningtypes = "wWiI"

For example, the severity of error messages from gcc
        averagergui.cpp|18 warning| unused parameter ‘file’ ~
        averagergui.cpp|33 error| expected class-name before ‘I’ ~
can be parsed by adding the following lines to your .vimrc >
        let &errorformat="%f:%l: %t%*[^:]:%m," . &errorformat
        let &errorformat="%f:%l:%c: %t%*[^:]:%m," . &errorformat
        let errormarker_warningtypes = "wW"

If you use a different locale than English, this may be also needed: >
        set makeprg=LANGUAGE=C\ make

==============================================================================
3. CREDITS                                               *errormarker-credits*

Author: Michael Hofmann <mh21 at piware dot de>

==============================================================================
4. CHANGELOG                                           *errormarker-changelog*

0.1.11  - changelog fix
0.1.10  - removes accidental dependency on NerdEcho
0.1.9   - fixes Win32 icon display
0.1.8   - check for Vim version
0.1.7   - fixes gcc error message parsing example
0.1.6   - support for GetLatestVimScripts (vimscript#642)
0.1.5   - clarified documentation about paths
0.1.4   - fixes icon name and variable escaping
0.1.3   - customizable signs
        - distinguishes between warnings and errors
0.1.2   - documentation
0.1.1   - handles nonexistent icons gracefully
        - tooltips only used if Vim has balloon-eval support
0.1     - initial release

==============================================================================
=== END_DOC

" vim:ft=vim foldmethod=marker tw=78
