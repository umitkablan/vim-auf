if exists('g:loaded_auffmt_remark_md_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_remark_md_definition = 1

let s:definition = {
            \ 'ID'        : 'remark_md',
            \ 'executable': 'remark',
            \ 'filetypes' : ['markdown'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#remark_md#define() abort
    return s:definition
endfunction

function! auf#formatters#remark_md#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'remark --silent --no-color ' . ' ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
