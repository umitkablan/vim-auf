if exists('g:loaded_auffmt_rubocop_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_rubocop_definition = 1

let s:definition = {
            \ 'ID'        : 'rubocop',
            \ 'executable': 'rubocop',
            \ 'filetypes' : ['ruby'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#rubocop#define() abort
    return s:definition
endfunction

function! auf#formatters#rubocop#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    " The pipe to sed is required to remove some rubocop output that could not
    " be suppressed.
    let style = '--auto-correct -o /dev/null -s ' . bufname('%')
    return 'rubocop ' . style . ' < ' . a:inpath . ' \| sed /^===/d'
endfunction

call auf#registry#RegisterFormatter(s:definition)
