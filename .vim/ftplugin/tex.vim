" this is mostly a matter of taste. but LaTeX looks good with just a bit
" of indentation.
set sw=2
set ts=2

" TIP: if you write your \label's as \label{fig:something}, then if you
" type in \ref{fig: and press <C-n> you will automatically cycle through
" all the figure labels. Very useful!
set iskeyword+=:

" To err is human
set spell

" Prepend CTRL on Alt-key mappings: Alt-{B,C,L,I}
"imap <C-M-b> <Plug>Tex_MathBF
"imap <C-M-c> <Plug>Tex_MathCal
"imap <C-M-l> <Plug>Tex_LeftRight
"imap <C-M-i> <Plug>Tex_InsertItem

let g:Tex_DefaultTargetFormat = 'pdf'

let g:Tex_CompileRule_dvi = 'vimlatex latex --interaction=nonstopmode $*'
let g:Tex_CompileRule_ps = 'dvips -Pwww -o $*.ps $*.dvi'
let g:Tex_CompileRule_pspdf = 'ps2pdf $*.ps'
let g:Tex_CompileRule_dvipdf = 'dvipdfm $*.dvi'
let g:Tex_CompileRule_pdf = 'vimlatex pdflatex --interaction=nonstopmode $*'

let g:Tex_TreatMacViewerAsUNIX = 1
let g:Tex_ExecuteUNIXViewerInForeground = 1
let g:Tex_ViewRule_dvi = 'texniscope'
let g:Tex_ViewRule_ps = 'skim'
let g:Tex_ViewRule_pdf = 'skim'

let g:Tex_FormatDependency_ps  = 'dvi,ps'
let g:Tex_FormatDependency_pspdf = 'dvi,ps,pspdf'
let g:Tex_FormatDependency_dvipdf = 'dvi,dvipdf'

" TODO: more flexible way of enabling/disabling warnings.
let g:Tex_IgnoredWarnings ='
            \"Underfull\n".
            \"Overfull\n".
            \"specifier changed to\n".
            \"You have requested\n".
            \"Missing number, treated as zero.\n".
            \"There were undefined references\n".
            \"Citation %.%# undefined\n".
            \"\oval, \circle, or \line size unavailable\n"'
