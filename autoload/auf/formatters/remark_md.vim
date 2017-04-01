if exists('g:loaded_auffmt_remark_md_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_remark_md_definition = 1

let s:definition = {
            \ 'ID'        : 'remark_md',
            \ 'executable': 'remark',
            \ 'filetypes' : ['markdown']
            \ }

function! auf#formatters#remark_md#define() abort
    return s:definition
endfunction

function! auf#formatters#remark_md#cmdArgs(ftype) abort
    if a:ftype
    endif
    return '--silent --no-color'
endfunction

call auf#registry#RegisterFormatter(s:definition)
