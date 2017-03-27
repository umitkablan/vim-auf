if exists('g:loaded_auffmt_stylish_haskell_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_stylish_haskell_definition = 1

let s:definition = {
            \ 'ID'        : 'stylish_haskell',
            \ 'executable': 'stylish-haskell',
            \ 'filetypes' : ['haskell'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#stylish_haskell#define() abort
    return s:definition
endfunction

function! auf#formatters#stylish_haskell#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'stylish-haskell ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
