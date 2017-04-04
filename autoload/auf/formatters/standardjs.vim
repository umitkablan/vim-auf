if exists('g:loaded_auffmt_standardjs_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_standardjs_definition = 1

let s:definition = {
        \ 'ID'        : 'standardjs',
        \ 'executable': 'standard',
        \ 'filetypes' : ['javascript']
        \ }

function! auf#formatters#standardjs#define() abort
    return s:definition
endfunction

function! auf#formatters#standardjs#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '--fix'
endfunction

call auf#registry#RegisterFormatter(s:definition)
