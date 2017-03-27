if exists('g:loaded_auffmt_gofmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_gofmt_definition = 1

let s:definition = {
            \ 'ID'        : 'gofmt',
            \ 'executable': 'gofmt',
            \ 'filetypes' : ['go'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#gofmt#define() abort
    return s:definition
endfunction

function! auf#formatters#gofmt#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = ''
    if get(g:, 'auffmt_gofmt_tabs', 1)
        let style = '-tabs=' . (&expandtab ? 'false' : 'true') . ' -tabwidth=' . shiftwidth()
    endif
    return 'gofmt ' . style . ' ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
