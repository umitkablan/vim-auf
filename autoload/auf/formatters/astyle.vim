if exists('g:loaded_auffmt_astyle_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_astyle_definition = 1

let s:definition = {
      \ 'ID'        : 'astyle',
      \ 'executable': 'astyle',
      \ 'filetypes' : ['c', 'cpp', 'cs', 'java']
      \ }

function! auf#formatters#astyle#define() abort
  return s:definition
endfunction

function! auf#formatters#astyle#cmdArgs(ftype) abort
  let mode = '--mode=' . a:ftype
  let options = ''
  if filereadable('.astylerc')
    let options = '--options=.astylerc'
  elseif filereadable(expand('~/.astylerc')) || exists('$ARTISTIC_STYLE_OPTIONS')
  else
    if a:ftype ==# 'c' || a:ftype ==# 'cpp'
      let options = '--style=ansi -pcH'
    elseif a:ftype ==# 'cs'
      let options = '--style=ansi --indent-namespaces -pcH'
    elseif a:ftype ==# 'java'
      let options = '--style=java -pcH'
    endif
    let options .= (&expandtab ? 's'.shiftwidth() : 't')
  endif
  return mode . ' ' . options . ' <'
endfunction

call auf#registry#RegisterFormatter(s:definition)
