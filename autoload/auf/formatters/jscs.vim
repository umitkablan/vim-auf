if exists('g:loaded_auffmt_jscs_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_jscs_definition = 1

let s:definition = {
        \ 'ID'        : 'jscs',
        \ 'executable': 'jscs',
        \ 'filetypes' : ['javascript']
        \ }

function! auf#formatters#jscs#define() abort
    return s:definition
endfunction

function! auf#formatters#jscs#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '-x -n <'
endfunction

call auf#registry#RegisterFormatter(s:definition)
