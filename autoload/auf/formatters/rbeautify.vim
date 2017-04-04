if exists('g:loaded_auffmt_rbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_rbeautify_definition = 1

let s:definition = {
        \ 'ID'        : 'rbeautify',
        \ 'executable': 'rbeautify',
        \ 'filetypes' : ['ruby']
        \ }

function! auf#formatters#rbeautify#define() abort
    return s:definition
endfunction

function! auf#formatters#rbeautify#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return &expandtab ? '-s -c '.shiftwidth() : '-t'
endfunction

call auf#registry#RegisterFormatter(s:definition)
