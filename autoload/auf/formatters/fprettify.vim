if exists('g:loaded_auffmt_fprettify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_fprettify_definition = 1

let s:definition = {
            \ 'ID'        : 'fprettify',
            \ 'executable': 'fprettify',
            \ 'filetypes' : ['fortran']
            \ }

function! auf#formatters#fprettify#define() abort
    return s:definition
endfunction

function! auf#formatters#fprettify#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '--no-report-errors --indent=' . &shiftwidth
endfunction

call auf#registry#RegisterFormatter(s:definition)
