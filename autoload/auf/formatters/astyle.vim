if exists('g:loaded_auffmt_astyle_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_astyle_definition = 1

let s:definition = {
      \ 'ID'        : 'astyle',
      \ 'executable': 'astyle',
      \ 'filetypes' : ['c', 'cpp', 'cs', 'java'],
      \ 'probefiles' : ['.astylerc']
      \ }

function! auf#formatters#astyle#define() abort
  return s:definition
endfunction

function! auf#formatters#astyle#cmdArgs(ftype, confpath) abort
  let options = ''
  if len(a:confpath)
    let options = '--options=' . a:confpath
  elseif filereadable(expand('~/.astylerc')) || exists('$ARTISTIC_STYLE_OPTIONS')
  else
    if a:ftype ==# 'c' || a:ftype ==# 'cpp'
      let options = '--mode=c --style=ansi -pcH'
    elseif a:ftype ==# 'cs'
      let options = '--mode=cs --style=ansi --indent-namespaces -pcH'
    elseif a:ftype ==# 'java'
      let options = '--mode=java --style=java -pcH'
    endif
    let options .= (&expandtab ? 's'.shiftwidth() : 't')
  endif
  return options . ' <'
endfunction

call auf#registry#RegisterFormatter(s:definition)
