if exists('g:loaded_auffmt_tsfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_tsfmt_definition = 1

let s:definition = {
            \ 'ID'        : 'tsfmt',
            \ 'executable': 'tsfmt',
            \ 'filetypes' : ['typescript'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#tsfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#tsfmt#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'tsfmt ' . a:inpath . ' ' . bufname('%')
endfunction

call auf#registry#RegisterFormatter(s:definition)
