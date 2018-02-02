if exists('g:loaded_auffmt_luaformatter_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_luaformatter_definition = 1

let s:definition = {
        \ 'ID'        : 'luaformatter',
        \ 'executable': 'luaformatter',
        \ 'filetypes' : ['lua']
        \ }

function! auf#formatters#luaformatter#define() abort
    return s:definition
endfunction

function! auf#formatters#luaformatter#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    let style = ''
    if &l:expandtab
        let style .= '-s ' . &l:tabstop
    else
        let style .= '-t 1'
    endif
    if &l:fileformat ==# 'mac'
        let style .= ' -d mac'
    elseif &l:fileformat ==# 'dos'
        let style .= ' -d windows'
    else
        let style .= ' -d unix'
    endif
    return style
endfunction

function! auf#formatters#luaformatter#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
