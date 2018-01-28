if exists('g:loaded_auffmt_fsqlf_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_fsqlf_definition = 1

let s:definition = {
        \ 'ID'        : 'fsqlf',
        \ 'executable': 'fsqlf',
        \ 'filetypes' : ['sql'],
        \ 'probefiles' : ['.fsqlf.conf', '_fsqlf.conf']
        \ }

function! auf#formatters#fsqlf#define() abort
    return s:definition
endfunction

function! auf#formatters#fsqlf#cmdArgs(ftype, confpath) abort
    if a:ftype
    endif
    let style = ''
    if a:confpath
        let style .= ' --config-file ' . a:confpath
    endif
    return style . ' -i '
endfunction

function! auf#formatters#fsqlf#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' -o ' . a:outpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
