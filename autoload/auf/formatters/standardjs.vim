if exists('g:loaded_auffmt_standardjs_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_standardjs_definition = 1

let s:definition = {
        \ 'ID'        : 'standardjs',
        \ 'executable': 'standard',
        \ 'filetypes' : ['javascript'],
        \ 'ranged'    : 0,
        \ 'fileout'   : 0
        \ }

function! auf#formatters#standardjs#define() abort
    return s:definition
endfunction

function! auf#formatters#standardjs#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'standard --fix ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
