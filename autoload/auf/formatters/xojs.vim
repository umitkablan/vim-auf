if exists('g:loaded_auffmt_xojs_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_xojs_definition = 1

let s:definition = {
        \ 'ID'        : 'xojs',
        \ 'executable': 'xo',
        \ 'filetypes' : ['javascript']
        \ }

function! auf#formatters#xojs#define() abort
    return s:definition
endfunction

function! auf#formatters#xojs#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '--fix'
endfunction

function! auf#formatters#xojs#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' -o ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
