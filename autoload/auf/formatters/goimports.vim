if exists('g:loaded_auffmt_goimports_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_goimports_definition = 1

let s:definition = {
            \ 'ID'        : 'goimports',
            \ 'executable': 'goimports',
            \ 'filetypes' : ['go'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#goimports#define() abort
    return s:definition
endfunction

function! auf#formatters#goimports#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'goimports ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
