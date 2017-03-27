if exists('g:loaded_auffmt_dartfmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_dartfmt_definition = 1

let s:definition = {
            \ 'ID'        : 'dartfmt',
            \ 'executable': 'dartfmt',
            \ 'filetypes' : ['dart'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#dartfmt#define() abort
    return s:definition
endfunction

function! auf#formatters#dartfmt#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    return 'dartfmt ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
