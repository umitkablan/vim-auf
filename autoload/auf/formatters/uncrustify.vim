if exists('g:loaded_auffmt_uncrustify_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_uncrustify_definition = 1

let s:definition = {
      \ 'ID'        : 'uncrustify',
      \ 'executable': 'uncrustify',
      \ 'filetypes' : ['c', 'cpp', 'cs', 'java', 'objc', 'd', 'pawn', 'vala'],
      \ 'probefiles': ['uncrustify.cfg', '.uncrustify.cfg']
      \ }

function! auf#formatters#uncrustify#define() abort
  return s:definition
endfunction

function! auf#formatters#uncrustify#cmdArgs(ftype, confpath) abort
  if a:ftype
  endif
  let [style, c] = ['', '']
  if len(a:confpath)
    let c = a:confpath
  else
    let c = get(g:, 'auffmt_uncrustify_config', '')
  endif
  if c
    let style = '-c ' . c
  endif
  return style . ' -f'
endfunction

call auf#registry#RegisterFormatter(s:definition)
