if exists('g:loaded_auffmt_htmlbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_htmlbeautify_definition = 1

let s:definition = {
        \ 'ID'        : 'htmlbeautify',
        \ 'executable': 'html-beautify',
        \ 'filetypes' : ['html']
        \ }

function! auf#formatters#htmlbeautify#define() abort
    return s:definition
endfunction

function! auf#formatters#htmlbeautify#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    let style = '-'.(&expandtab ? 's '.shiftwidth() : 't')
    return style . ' -f'
endfunction

call auf#registry#RegisterFormatter(s:definition)
