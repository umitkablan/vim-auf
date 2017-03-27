if exists('g:loaded_auffmt_yapf_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_yapf_definition = 1

let s:definition = {
            \ 'ID'        : 'yapf',
            \ 'executable': 'yapf',
            \ 'filetypes' : ['python'],
            \ 'ranged'    : 1,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#yapf#define() abort
    return s:definition
endfunction

function! auf#formatters#yapf#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif

    let style = '--style="{based_on_style:' .
                \ (exists('g:auffmt_yapf_style') ? g:auffmt_yapf_style : 'pep8') . ',' .
                \ 'indent_width:' . &shiftwidth . ',' .
                \ 'column_limit:' . &textwidth .
                \ '}"'
    return 'yapf ' . style . ' ' . '-l ' . a:line0 . '-' . a:line1 . ' <' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
