if exists('g:loaded_auffmt_jsbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_jsbeautify_definition = 1

let s:definition = {
      \ 'ID'        : 'jsbeautify',
      \ 'executable': 'js-beautify',
      \ 'filetypes' : ['javascript', 'json'],
      \ 'ranged'    : 0,
      \ 'fileout'   : 0
      \ }

function! auf#formatters#jsbeautify#define() abort
  return s:definition
endfunction

function! auf#formatters#jsbeautify#cmd(ftype, inpath, outpath, line0, line1) abort
  if a:outpath || a:line0 || a:line1 || a:ftype
  endif

  let style = ''
  if filereadable('.jsbeautifyrc')
  elseif filereadable(expand('~/.jsbeautifyrc'))
  else
    let style = '-X -' .
          \ (&expandtab ? 's '.shiftwidth() : 't') . (&textwidth ? ' -w '.&textwidth : '')
  endif
  return 'js-beautify ' . style . ' -f ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
