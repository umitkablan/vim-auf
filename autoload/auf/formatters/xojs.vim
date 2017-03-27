if exists('g:loaded_auffmt_xojs_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_xojs_definition = 1

let s:definition = {
        \ 'ID'        : 'xojs',
        \ 'executable': 'xo',
        \ 'filetypes' : ['javascript'],
        \ 'ranged'    : 0,
        \ 'fileout'   : 1
        \ }

function! auf#formatters#xojs#define() abort
    return s:definition
endfunction

function! auf#formatters#xojs#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'xo --fix ' . a:inpath . ' -o ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
