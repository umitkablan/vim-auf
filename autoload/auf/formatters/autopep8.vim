if exists('g:loaded_auffmt_autopep8_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_autopep8_definition = 1

let s:definition = {
            \ 'ID'        : 'autopep8',
            \ 'executable': 'autopep8',
            \ 'filetypes' : ['python'],
            \ 'ranged'    : 1,
            \ 'fileout'   : 0
            \ }

function! auf#formatters#autopep8#define() abort
    return s:definition
endfunction

function! auf#formatters#autopep8#cmd(ftype, inpath, outpath, line0, line1) abort
    if a:outpath || a:line0 || a:line1 || a:ftype
    endif

    " Autopep8 will not do indentation fixes when a range is specified, so we
    " only pass a range when there is a visual selection that is not the
    " entire file. See #125.
    let range = '-' . (s:doesRangeEqualBuffer(a:line0, a:line1) ? ' --range ' . a:line0 . ' ' . a:line1 : '')
    let style = (&textwidth ? '--max-line-length=' . &textwidth : '')
    return 'autopep8 ' . range . ' ' . style . ' <' . a:inpath
endfunction

" There doesn't seem to be a reliable way to detect if are in some kind of visual mode,
" so we use this as a workaround. We compare the length of the file against
" the range arguments. If there is no range given, the range arguments default
" to the entire file, so we return false if the range comprises the entire file.
function! s:doesRangeEqualBuffer(first, last) abort
    return line('$') != a:last - a:first + 1
endfunction

call auf#registry#RegisterFormatter(s:definition)
