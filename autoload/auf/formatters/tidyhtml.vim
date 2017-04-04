if exists('g:loaded_auffmt_tidyhtml_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_tidyhtml_definition = 1

let s:definition = {
        \ 'ID'        : 'tidyhtml',
        \ 'executable': 'tidy',
        \ 'filetypes' : ['html', 'xhtml', 'xml']
        \ }

function! auf#formatters#tidyhtml#define() abort
    return s:definition
endfunction

function! auf#formatters#tidyhtml#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    let style = ''
    if a:ftype ==# 'xml'
        let style = '-xml'
    elseif a:ftype ==# 'xhtml'
        let style = '-asxhtml'
    endif
    let style .= ' --indent auto --indent-spaces ' . shiftwidth() . ' --vertical-space yes --tidy-mark no' .
                \ '-wrap ' . &textwidth
    return '-q --show-errors 0 --show-warnings 0 --force-output ' . style
endfunction

function! auf#formatters#tidyhtml#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' -o ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
