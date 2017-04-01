if exists('g:loaded_auffmt_rustfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_rustfmt_definition = 1

let s:definition = {
            \ 'ID'        : 'rustfmt',
            \ 'executable': 'rustfmt',
            \ 'filetypes' : ['rust']
            \ }

function! auf#formatters#rustfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#rustfmt#cmdArgs(ftype) abort
    if a:ftype
    endif
    return ''
endfunction

call auf#registry#RegisterFormatter(s:definition)
