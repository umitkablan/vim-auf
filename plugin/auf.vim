if exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_plugin = 1

runtime! plugin/auf_defaults.vim

if g:auf_diffcmd ==# '' || !executable(g:auf_diffcmd)
    augroup Auf_Error
        autocmd!
        autocmd VimEnter *
            \ call s:echoErrorMsg("Auf: Can't start! \
                \Couldn't locate 'diff' program (defined in g:auf_diffcmd as '"
                \ . g:auf_diffcmd . "').")
    augroup END
    finish
endif
if g:auf_filterdiffcmd ==# '' || !executable(g:auf_filterdiffcmd)
    augroup Auf_Error
        autocmd!
        autocmd VimEnter *
            \ call s:echoErrorMsg("Auf: Can't start! \
                \Couldn't locate 'filterdiff' program (defined in g:auf_filterdiffcmd as '"
                \ . g:auf_filterdiffcmd . "').")
    augroup END
    finish
endif

let g:auf_diffcmd .= ' -u '

execute 'highlight def link AufErrLine ' . g:auf_showdiff_synmatch

function! AufFormatRange(line1, line2) abort
    let overwrite = 1
    call auf#format#TryFormatter(a:line1, a:line2, auf#format#getCurrentProgram(), overwrite, 'AufErrLine')
endfunction

" Save and recall window state to prevent vim from jumping to line 1: Beware
" that it should be done here due to <line1>,<line2> range.
command! -nargs=? -range=% -complete=filetype -bang -bar Auf
    \ let ww=winsaveview()|
    \ <line1>,<line2>call auf#format#TryAllFormatters(<bang>0, <f-args>)|
    \ call winrestview(ww)
command! -nargs=0 -bar AufJIT call auf#format#justInTimeFormat('AufErrLine')

" Create commands for iterating through formatter list
command! AufNextFormatter call auf#format#NextFormatter()
command! AufPrevFormatter call auf#format#PreviousFormatter()
command! AufCurrFormatter call auf#format#CurrentFormatter()

command! AufShowDiff call auf#format#ShowDiff()
command! AufClearHi call auf#util#clearHighlights("AufErrLine")

augroup Auf_Auto
    autocmd!
    autocmd BufRead *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 &&
        \    g:auf_highlight_errs |
        \   Auf |
        \ endif
    autocmd BufRead *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 &&
        \    g:auf_hijack_gq |
        \   setl formatexpr=AufFormatRange(v:lnum,v:lnum+v:count-1) |
        \ endif
    autocmd BufWritePre *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 &&
        \    g:auf_jitformat |
        \   AufJIT |
        \ endif
    autocmd BufWritePost *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 &&
        \    g:auf_highlight_errs |
        \   Auf |
        \ endif
augroup END

