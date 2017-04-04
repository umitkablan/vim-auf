if exists('g:loaded_auffmt_stylish_haskell_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_stylish_haskell_definition = 1

let s:definition = {
            \ 'ID'        : 'stylish_haskell',
            \ 'executable': 'stylish-haskell',
            \ 'filetypes' : ['haskell']
            \ }

function! auf#formatters#stylish_haskell#define() abort
    return s:definition
endfunction

function! auf#formatters#stylish_haskell#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return ''
endfunction

call auf#registry#RegisterFormatter(s:definition)
