if exists('g:loaded_auffmt_rustfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_rustfmt_definition = 1

let s:definition = {
            \ 'ID'        : 'rustfmt',
            \ 'executable': 'rustfmt',
            \ 'filetypes' : ['rust'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#rustfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#rustfmt#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'rustfmt ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
