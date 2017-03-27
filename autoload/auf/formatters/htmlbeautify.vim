if exists('g:loaded_auffmt_htmlbeautify_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_htmlbeautify_definition = 1

let s:definition = {
        \ 'ID'        : 'htmlbeautify',
        \ 'executable': 'html-beautify',
        \ 'filetypes' : ['html'],
        \ 'ranged'    : 0,
        \ 'fileout'   : 0
        \ }

function! auf#formatters#htmlbeautify#define() abort
    return s:definition
endfunction

function! auf#formatters#htmlbeautify#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = '-'.(&expandtab ? 's '.shiftwidth() : 't')
    return 'html-beautify -f ' . a:inpath . ' ' . style
endfunction

call auf#registry#RegisterFormatter(s:definition)
