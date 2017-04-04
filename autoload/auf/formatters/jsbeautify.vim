if exists('g:loaded_auffmt_jsbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_jsbeautify_definition = 1

let s:definition = {
      \ 'ID'        : 'jsbeautify',
      \ 'executable': 'js-beautify',
      \ 'filetypes' : ['javascript', 'json'],
      \ 'probefiles': ['.jsbeautifyrc']
      \ }

function! auf#formatters#jsbeautify#define() abort
  return s:definition
endfunction

function! auf#formatters#jsbeautify#cmdArgs(ftype) abort
  if a:ftype
  endif

  let style = ''
  if filereadable('.jsbeautifyrc')
  elseif filereadable(expand('~/.jsbeautifyrc'))
  else
    let style = '-X -' .
          \ (&expandtab ? 's '.shiftwidth() : 't') . (&textwidth ? ' -w '.&textwidth : '')
  endif
  return style . ' -f'
endfunction

call auf#registry#RegisterFormatter(s:definition)
