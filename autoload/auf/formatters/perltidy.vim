if exists('g:loaded_auffmt_perltidy_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_perltidy_definition = 1

let s:definition = {
            \ 'ID'        : 'perltidy',
            \ 'executable': 'perltidy',
            \ 'filetypes' : ['perl'],
            \ 'probefiles': ['.perltidyrc']
            \ }

function! auf#formatters#perltidy#define() abort
    return s:definition
endfunction

function! auf#formatters#perltidy#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    let style = '--perl-best-practices --format-skipping -q'
    " use perltidyrc file if readable
    if (has('win32') && (filereadable('perltidy.ini') ||
                \ filereadable($HOMEPATH.'/perltidy.ini'))) ||
                \ ((has('unix') ||
                \ has('mac')) && (len(a:confpath) ||
                \ filereadable('~/.perltidyrc') ||
                \ filereadable('/usr/local/etc/perltidyrc') ||
                \ filereadable('/etc/perltidyrc')))
        let style = '-q -st'
    endif
    return style
endfunction

call auf#registry#RegisterFormatter(s:definition)
