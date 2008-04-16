" ---------------------------------------------------------------------
" File: bro.vim
" Birthday: Wed Aug 03 10:41:01 PDT 2005 
" Author: Martin Casado
"         (... also without a clue about writing VIM syntax files
"           thanks python.vim & c.vim!)
"
"         enhanced by Matthias Vallentin 
"
" * PROBLEMS *
"   - keywords within hyphenated words (e.g. "port" in port-name) are
"     highlighted
"   - patterns are not well recognized
" 
" ---------------------------------------------------------------------

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword broStatement     break continue del
syn keyword broStatement     case
syn keyword broStatement     alarm using
syn keyword broStatement     default delete else 
syn keyword broStatement     event efmt 
syn keyword broStatement     local match next
syn keyword broStatement     print return schedule
syn keyword broStatement     switch this type

syn keyword broStorageClass  const global redef global_attr export

syn keyword broOperator      in add of any

syn keyword broStatement     function nextgroup=broFunction skipwhite
syn match   broFunction      "[a-zA-Z_][a-zA-Z0-9_]*" contained

syn keyword broType          addr bool count 
syn keyword broType          counter double enum 
syn keyword broType          file int interval 
syn keyword broType          list net pattern    
syn keyword broType          port record set
syn keyword broType          string subnet table
syn keyword broType          timer time union
syn keyword broType          vector 

syn keyword broDate          day days hr hrs
syn keyword broDate          min mins sec
syn keyword broDate          secs msec msecs
syn keyword broDate          usec usecs

syn match broPreCondit		"@\(load\|prefixes\)"

syn keyword broRepeat        for

syn keyword broConditional   if else

" String and Character constants
" Highlight special characters (those which have a backslash) differently
syn match     cSpecial        display contained "\\\(x\x\+\|\o\{1,3}\|.\|$\)"
syn match     cSpecial        display contained "\\\(u\x\{4}\|U\x\{8}\)"
syn match     cFormat         display "%\(\d\+\$\)\=[-+' #0*]*\(\d*\|\*\|\*\d\+\$\)\(\.\(\d*\|\*\|\*\d\+\$\)\)\=\([hlL]\|ll\)\=\([bdiuoxXDOUfeEgGcCsSpn]\|\[\^\=.[^]]*\]\)" contained
syn match     cFormat         display "%%" contained
syn region    cString         start=+L\="+ skip=+\\\\\|\\"+ end=+"+ contains=cSpecial,cFormat,@Spell

syn match  broEscape         +\\[abfnrtv'"\\]+ contained
syn match  broEscape         "\\\o\{1,3}" contained
syn match  broEscape         "\\x\x\{2}" contained
syn match  broEscape         "\(\\u\x\{4}\|\\U\x\{8}\)" contained
syn match  broEscape         "\\$"

syn match   broComment       "#.*$" contains=broTodo
syn keyword broTodo          TODO FIXME XXX contained

" numbers (including longs and complex)
syn match   broNumber      "\<0x\x\+[Ll]\=\>"
syn match   broNumber      "\<\d\+[LljJ]\=\>"
syn match   broNumber      "\.\d\+\([eE][+-]\=\d\+\)\=[jJ]\=\>"
syn match   broNumber      "\<\d\+\.\([eE][+-]\=\d\+\)\=[jJ]\=\>"
syn match   broNumber      "\<\d\+\.\d\+\([eE][+-]\=\d\+\)\=[jJ]\=\>"

if version >= 508 || !exists("did_bro_syn_inits")
  if version <= 508
    let did_bro_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

" The default methods for highlighting.  Can be overridden later
  HiLink broStatement        Statement
  HiLink broFunction         Function
  HiLink broConditional      Conditional
  HiLink broRepeat           Repeat
  HiLink broEscape           Special
  HiLink broType             Type
  HiLink broPreCondit        PreCondit
  HiLink broComment          Comment
  HiLink broTodo             Todo
  HiLink broNumber           Number
  HiLink broOperator         Operator
  HiLink broStorageClass     StorageClass 
  HiLink broDate             SpecialChar 
  HiLink cString             String
  HiLink cFormat             cSpecial
  HiLink cSpecial            SpecialChar

  delcommand HiLink
endif

let b:current_syntax = "bro"
