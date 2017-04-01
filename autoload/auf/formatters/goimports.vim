if exists('g:loaded_auffmt_goimports_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_goimports_definition = 1

let s:definition = {
            \ 'ID'        : 'goimports',
            \ 'executable': 'goimports',
            \ 'filetypes' : ['go']
            \ }

function! auf#formatters#goimports#define() abort
    return s:definition
endfunction

function! auf#formatters#goimports#cmdArgs(ftype) abort
    if a:ftype
    endif
    return ''
endfunction

call auf#registry#RegisterFormatter(s:definition)
