if exists('g:loaded_auffmt_clangformat_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_clangformat_definition = 1

let s:definition = {
      \ 'ID'        : 'clangformat',
      \ 'executable': 'clang-format',
      \ 'filetypes' : ['c', 'cpp', 'objc']
      \ }

function! auf#formatters#clangformat#define() abort
  return s:definition
endfunction

function! auf#formatters#clangformat#cmdArgs(ftype) abort
  let style = ''
  let confpath = s:clangformatGetConfig()
  if len(confpath)
    let style = '-style="{' . s:clangformatParseConfig(confpath) . '}"'
  else
    if a:ftype ==# 'cpp'
      let style = '-style="{' .
            \ 'BasedOnStyle:WebKit, ' .
            \ 'AlignTrailingComments:true, ' .
            \ (&textwidth ? 'ColumnLimit:'.&textwidth.', ' : '') .
            \ (&expandtab ? 'UseTab:Never, IndentWidth:'.shiftwidth() : 'UseTab:Always') .
            \ '}"'
    endif
  endif
  return '--assume-filename="'.expand('%:.') . '" ' . style
endfunction

function! auf#formatters#clangformat#cmdAddRange(cmd, line0, line1) abort
  return a:cmd . ' -lines=' . a:line0 . ':' . a:line1
endfunction

function! s:clangformatGetConfig() abort
  let ll = findfile('.clang-format', expand('%:p:h').';')
  if len(ll)
    return ll
  endif
  let ll = findfile('_clang-format', expand('%:p:h').';')
  if len(ll)
    return ll
  endif
  let conf = get(g:, 'auffmt_clangformat_config', '')
  if len(conf)
    return conf
  endif
  return ''
endfunction

function! s:clangformatParseConfig(fpath) abort
  let cnffile = join(readfile(a:fpath), ', ')
  return substitute(cnffile, "'", "''", 'g')
endfunction

call auf#registry#RegisterFormatter(s:definition)
