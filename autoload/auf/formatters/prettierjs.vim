if exists('g:loaded_auffmt_prettierjs_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_prettierjs_definition = 1

let s:definition = {
      \ 'ID'        : 'prettierjs',
      \ 'executable': 'prettier',
      \ 'filetypes' : ['javascript', 'json', 'typescript', 'flow', 'css', 'less', 'scss', 'md'],
      \ 'probefiles': ['.prettierrc', 'prettier.config.js']
    \ } " probefiles => 'package.json'?

function! auf#formatters#prettierjs#define() abort
  return s:definition
endfunction

function! auf#formatters#prettierjs#cmdArgs(ftype, confpath) abort
  if a:ftype
  endif

  let style = '--no-color'
  if len(a:confpath)
    let style .= ' --config ' . a:confpath
  elseif filereadable(expand('~/.prettierrc'))
    let style .= ' --config ~/.prettierrc'
  else
    let style .=
          \ ' --use-tabs ' . (&l:expandtab ? 'true' : 'false') .
          \ ' --tab-width ' . (&l:shiftwidth ? &l:shiftwidth : &l:tabstop) .
          \ (&textwidth ? ' --print-width '.&textwidth : '')
  endif
  return ' --stdin-filepath "'.expand('%:.') . '" ' . style
endfunction

function! auf#formatters#prettierjs#cmdAddRange(cmd, line0, line1) abort
  return a:cmd . ' --range-start ' . a:line0 . ' --range-end ' . (a:line1+1)
endfunction

call auf#registry#RegisterFormatter(s:definition)
