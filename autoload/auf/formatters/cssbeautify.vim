if exists('g:loaded_auffmt_cssbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_cssbeautify_definition = 1

let s:definition = {
            \ 'ID'        : 'cssbeautify',
            \ 'executable': 'css-beautify',
            \ 'filetypes' : ['css']
            \ }

function! auf#formatters#cssbeautify#define() abort
    return s:definition
endfunction

function! auf#formatters#cssbeautify#cmdArgs(ftype) abort
    if a:ftype
    endif
    return '-f - -s ' . shiftwidth()
endfunction

call auf#registry#RegisterFormatter(s:definition)
