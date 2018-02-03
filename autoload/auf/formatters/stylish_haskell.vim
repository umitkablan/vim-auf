if exists('g:loaded_auffmt_stylish_haskell_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_stylish_haskell_definition = 1

let s:definition = {
            \ 'ID'        : 'stylish_haskell',
            \ 'executable': 'stylish-haskell',
            \ 'filetypes' : ['haskell']
            \ }

function! auf#formatters#stylish_haskell#define() abort
    return s:definition
endfunction

function! auf#formatters#stylish_haskell#cmdArgs(ftype, confpath) abort
    if a:ftype
    endif
    let style = ''
    if a:confpath
        let style .= '-c ' . a:confpath
    endif
    if (exists('g:auf_verbosemode') && g:auf_verbosemode) ||
        \ (exists('g:verbose') && g:verbose)
        let style .= ' -v'
    endif
    return style
endfunction

call auf#registry#RegisterFormatter(s:definition)
