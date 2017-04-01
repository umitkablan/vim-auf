if exists('g:loaded_auffmt_rubocop_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_rubocop_definition = 1

let s:definition = {
            \ 'ID'        : 'rubocop',
            \ 'executable': 'rubocop',
            \ 'filetypes' : ['ruby']
            \ }

function! auf#formatters#rubocop#define() abort
    return s:definition
endfunction

function! auf#formatters#rubocop#cmdArgs(ftype) abort
    if a:ftype
    endif
    " The pipe to sed is required to remove some rubocop output that could not
    " be suppressed.
    return '--auto-correct -o /dev/null -s ' . bufname('%') . ' <'
endfunction

call auf#registry#RegisterFormatter(s:definition)
