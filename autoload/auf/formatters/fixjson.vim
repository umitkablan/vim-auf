if exists('g:loaded_auffmt_fixjson_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_fixjson_definition = 1

let s:definition = {
        \ 'ID'        : 'fixjson',
        \ 'executable': 'fixjson',
        \ 'filetypes' : ['json']
        \ }

function! auf#formatters#fixjson#define() abort
    return s:definition
endfunction

function! auf#formatters#fixjson#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '-i ' . (&l:expandtab ? &l:tabstop : shiftwidth())
endfunction

call auf#registry#RegisterFormatter(s:definition)
