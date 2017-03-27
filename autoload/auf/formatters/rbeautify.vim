if exists('g:loaded_auffmt_rbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_rbeautify_definition = 1

let s:definition = {
        \ 'ID'        : 'rbeautify',
        \ 'executable': 'rbeautify',
        \ 'filetypes' : ['ruby'],
        \ 'ranged'    : 0,
        \ 'fileout'   : 0
        \ }

function! auf#formatters#rbeautify#define() abort
    return s:definition
endfunction

function! auf#formatters#rbeautify#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = (&expandtab ? '-s -c '.shiftwidth() : '-t')
    return 'rbeautify ' . style. ' ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
