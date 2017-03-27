if exists('g:loaded_auffmt_jscs_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_jscs_definition = 1

let s:definition = {
        \ 'ID'        : 'jscs',
        \ 'executable': 'jscs',
        \ 'filetypes' : ['javascript'],
        \ 'ranged'    : 0,
        \ 'fileout'   : 0
        \ }

function! auf#formatters#jscs#define() abort
    return s:definition
endfunction

function! auf#formatters#jscs#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'jscs -x -n ' . ' < ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
