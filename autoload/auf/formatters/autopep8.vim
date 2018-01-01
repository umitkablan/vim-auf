if exists('g:loaded_auffmt_autopep8_definition') || !exists('g:loaded_auf_registry_autoload')
    finish
endif
let g:loaded_auffmt_autopep8_definition = 1

let s:definition = {
            \ 'ID'        : 'autopep8',
            \ 'executable': 'autopep8',
            \ 'filetypes' : ['python']
            \ }

function! auf#formatters#autopep8#define() abort
    return s:definition
endfunction

function! auf#formatters#autopep8#cmdArgs(ftype, confpath) abort
    if a:ftype || a:confpath
    endif
    " let style = (&textwidth ? '--max-line-length=' . &textwidth : '')
    return (&textwidth ? '--max-line-length=' . &textwidth : '')
endfunction

" function! auf#formatters#autopep8#cmdAddRange(cmd, line0, line1) abort
"     " Autopep8 will not do indentation fixes when a range is specified, so we
"     " only pass a range when there is a visual selection that is not the
"     " entire file. See #125.
"     let range = '-' . (s:doesRangeEqualBuffer(a:line0, a:line1) ? ' --range ' . a:line0 . ' ' . a:line1 : '')
"     return range . ' ' . a:cmd
" endfunction
"
" " There doesn't seem to be a reliable way to detect if are in some kind of visual mode,
" " so we use this as a workaround. We compare the length of the file against
" " the range arguments. If there is no range given, the range arguments default
" " to the entire file, so we return false if the range comprises the entire file.
" function! s:doesRangeEqualBuffer(first, last) abort
"     return line('$') != a:last - a:first + 1
" endfunction

call auf#registry#RegisterFormatter(s:definition)
