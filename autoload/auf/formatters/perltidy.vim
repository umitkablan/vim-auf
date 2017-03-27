if exists('g:loaded_auffmt_perltidy_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_perltidy_definition = 1

let s:definition = {
            \ 'ID'        : 'perltidy',
            \ 'executable': 'perltidy',
            \ 'filetypes' : ['perl'],
            \ 'ranged'    : 0,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#perltidy#define() abort
    return s:definition
endfunction

function! auf#formatters#perltidy#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif
    let style = '--perl-best-practices --format-skipping -q'
    " use perltidyrc file if readable
    if (has('win32') && (filereadable('perltidy.ini') ||
                \ filereadable($HOMEPATH.'/perltidy.ini'))) ||
                \ ((has('unix') ||
                \ has('mac')) && (filereadable('.perltidyrc') ||
                \ filereadable('~/.perltidyrc') ||
                \ filereadable('/usr/local/etc/perltidyrc') ||
                \ filereadable('/etc/perltidyrc')))
        let style = '-q -st'
    endif
    return 'perltidy ' . style . ' ' . a:inpath
endfunction

call auf#registry#RegisterFormatter(s:definition)
