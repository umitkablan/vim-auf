if exists('g:loaded_auffmt_sass_convert_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_sass_convert_definition = 1

let s:definition = {
            \ 'ID'        : 'sass_convert',
            \ 'executable': 'sass-convert',
            \ 'filetypes' : ['scss'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#sass_convert#define() abort
    return s:definition
endfunction

function! auf#formatters#sass_convert#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = '-F scss -T scss --indent ' . (&expandtab ? shiftwidth() : 't')
    return 'sass-convert' . style . ' ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
