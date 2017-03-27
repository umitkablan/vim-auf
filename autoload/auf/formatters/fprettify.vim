if exists('g:loaded_auffmt_fprettify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_fprettify_definition = 1

let s:definition = {
            \ 'ID'        : 'fprettify',
            \ 'executable': 'fprettify',
            \ 'filetypes' : ['fortran'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#fprettify#define() abort
    return s:definition
endfunction

function! auf#formatters#fprettify#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = '--no-report-errors --indent=' . &shiftwidth
    return 'fprettify ' . style . ' ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
