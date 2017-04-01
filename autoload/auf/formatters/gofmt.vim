if exists('g:loaded_auffmt_gofmt_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_gofmt_definition = 1

let s:definition = {
            \ 'ID'        : 'gofmt',
            \ 'executable': 'gofmt',
            \ 'filetypes' : ['go']
            \ }

function! auf#formatters#gofmt#define() abort
    return s:definition
endfunction

function! auf#formatters#gofmt#cmdArgs(ftype) abort
    if a:ftype
    endif
    let style = ''
    if get(g:, 'auffmt_gofmt_tabs', 1)
        let style = '-tabs=' . (&expandtab ? 'false' : 'true') . ' -tabwidth=' . shiftwidth()
    endif
    return style
endfunction

call auf#registry#RegisterFormatter(s:definition)
