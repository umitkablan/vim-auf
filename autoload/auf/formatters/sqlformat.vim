if exists('g:loaded_auffmt_sqlformat_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_sqlformat_definition = 1

let s:definition = {
        \ 'ID'        : 'sqlformat',
        \ 'executable': 'sqlformat',
        \ 'filetypes' : ['sql']
        \ }

function! auf#formatters#sqlformat#define() abort
    return s:definition
endfunction

function! auf#formatters#sqlformat#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    return '-k upper -i lower -r -a'
endfunction

function! auf#formatters#sqlformat#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' -o ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
