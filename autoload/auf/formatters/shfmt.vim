if exists('g:loaded_auffmt_shfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_shfmt_definition = 1

let s:definition = {
        \ 'ID'        : 'shfmt',
        \ 'executable': 'shfmt',
        \ 'filetypes' : ['sh']
        \ }

function! auf#formatters#shfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#shfmt#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '-i ' . (&l:expandtab ? &l:tabstop : 0)
endfunction

function! auf#formatters#shfmt#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' -w ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
