if exists('g:loaded_auffmt_sqlfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_sqlfmt_definition = 1

let s:definition = {
        \ 'ID'        : 'sqlfmt',
        \ 'executable': 'sqlfmt',
        \ 'filetypes' : ['sql']
        \ }

function! auf#formatters#sqlfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#sqlfmt#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return ''
endfunction

call auf#registry#RegisterFormatter(s:definition)
