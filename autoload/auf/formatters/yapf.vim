if exists('g:loaded_auffmt_yapf_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_yapf_definition = 1

let s:definition = {
            \ 'ID'        : 'yapf',
            \ 'executable': 'yapf',
            \ 'filetypes' : ['python']
            \ }

function! auf#formatters#yapf#define() abort
    return s:definition
endfunction

function! auf#formatters#yapf#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    let style = '--style="{based_on_style:' .
                \ (exists('g:auffmt_yapf_style') ? g:auffmt_yapf_style : 'pep8') . ',' .
                \ 'indent_width:' . &shiftwidth . ',' .
                \ 'column_limit:' . &textwidth .
                \ '}"'
    return style . ' <'
endfunction

function! auf#formatters#yapf#cmdAddRange(cmd, line0, line1) abort
    return a:cmd . ' -l ' . a:line0 . '-' . a:line1
endfunction

call auf#registry#RegisterFormatter(s:definition)
