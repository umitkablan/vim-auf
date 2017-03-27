if exists('g:loaded_auffmt_tidyhtml_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_tidyhtml_definition = 1

let s:definition = {
        \ 'ID'        : 'tidyhtml',
        \ 'executable': 'tidy',
        \ 'filetypes' : ['html', 'xhtml', 'xml'],
        \ 'ranged'    : 0,
        \ 'fileout'   : 1
        \ }

function! auf#formatters#tidyhtml#define() abort
    return s:definition
endfunction

function! auf#formatters#tidyhtml#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = ''
    if a:ftype ==# 'xml'
        let style = '-xml'
    elseif a:ftype ==# 'xhtml'
        let style = '-asxhtml'
    endif
    let style .= ' --indent auto --indent-spaces ' . shiftwidth() . ' --vertical-space yes --tidy-mark no' .
                \ '-wrap ' . &textwidth
    return 'tidy -q --show-errors 0 --show-warnings 0 --force-output ' . style . ' ' .
                \ a:inpath . ' -o ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
