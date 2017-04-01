if exists('g:loaded_auffmt_tsfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_tsfmt_definition = 1

let s:definition = {
            \ 'ID'        : 'tsfmt',
            \ 'executable': 'tsfmt',
            \ 'filetypes' : ['typescript']
            \ }

function! auf#formatters#tsfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#tsfmt#cmdArgs(ftype) abort
    if a:ftype
    endif
    return ''
endfunction

call auf#registry#RegisterFormatter(s:definition)
