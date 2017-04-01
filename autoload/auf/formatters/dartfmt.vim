if exists('g:loaded_auffmt_dartfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_dartfmt_definition = 1

let s:definition = {
            \ 'ID'        : 'dartfmt',
            \ 'executable': 'dartfmt',
            \ 'filetypes' : ['dart']
            \ }

function! auf#formatters#dartfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#dartfmt#cmdArgs(ftype) abort
    if a:ftype
    endif
    return ''
endfunction

call auf#registry#RegisterFormatter(s:definition)
