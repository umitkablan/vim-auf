if exists('g:loaded_auffmt_sass_convert_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_sass_convert_definition = 1

let s:definition = {
            \ 'ID'        : 'sass_convert',
            \ 'executable': 'sass-convert',
            \ 'filetypes' : ['scss']
            \ }

function! auf#formatters#sass_convert#define() abort
    return s:definition
endfunction

function! auf#formatters#sass_convert#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '-F scss -T scss --indent ' . (&expandtab ? shiftwidth() : 't')
endfunction

call auf#registry#RegisterFormatter(s:definition)
