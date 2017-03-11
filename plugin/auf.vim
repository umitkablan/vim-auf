if exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_plugin = 1

runtime! plugin/auf_defaults.vim

if g:auf_diffcmd ==# '' || !executable(g:auf_diffcmd)
    augroup Auf_Error
        autocmd!
        autocmd VimEnter *
            \ call auf#util#echoErrorMsg("Auf: Can't start! \
                \Couldn't locate 'diff' program (defined in g:auf_diffcmd as '"
                \ . g:auf_diffcmd . "').")
    augroup END
    finish
endif
if g:auf_filterdiffcmd ==# '' || !executable(g:auf_filterdiffcmd)
    augroup Auf_Error
        autocmd!
        autocmd VimEnter *
            \ call auf#util#echoErrorMsg("Auf: Can't start! \
                \Couldn't locate 'filterdiff' program (defined in g:auf_filterdiffcmd as '"
                \ . g:auf_filterdiffcmd . "').")
    augroup END
    finish
endif

let g:auf_diffcmd .= ' -u '

let s:AufErrLineSynCmd = 'highlight def link AufErrLine ' . g:auf_showdiff_synmatch
let s:AufChgLineSynCmd = 'highlight def link AufChgLine ' . g:auf_changedline_synmatch
augroup Auf_Auto_Syntax
    autocmd!
    autocmd Syntax execute s:AufErrLineSynCmd
    autocmd Syntax execute s:AufChgLineSynCmd
augroup END
execute s:AufErrLineSynCmd
execute s:AufChgLineSynCmd

function! AufFormatRange(line1, line2) abort
    call auf#util#logVerbose('AufFormatRange: ' . a:line1 . '-' . a:line2)
    let [overwrite, coward] = [1, 0]
    let [res, drift, resstr] = auf#format#TryFormatter(a:line1, a:line2, auf#format#getCurrentProgram(),
                \ overwrite, coward, 'AufErrLine')
    if res > 1
        call auf#util#echoErrorMsg('Auf-gq error: ' . resstr)
    else
        call auf#util#echoSuccessMsg('Auf-gq fine:' . resstr . ' ~' . drift)
    endif
    call auf#util#logVerbose('AufFormatRange: DONE')
endfunction

function! AufJit() abort
    try
        if !g:auf_jitformat
            call auf#util#echoErrorMsg('AufJit: JITing is disabled GLOBALLY')
        elseif exists('b:auf_jitformat') && !b:auf_jitformat
            call auf#util#echoErrorMsg('AufJit: JITing is disabled locally')
        elseif v:cmdbang
            call auf#util#echoErrorMsg('AufJit: JITing is disabled due to w! bang')
        else
            call auf#format#justInTimeFormat('AufErrLine')
        endif
    catch /.*/
        call auf#util#echoErrorMsg('AufJit: Exception: ' . v:exception)
    endtry
endfunction

function! AufBufReadPost() abort
    call auf#util#logVerbose('AufBufReadPost: START')
    if !exists('b:auf_highlight_lines_hlids')
        let b:auf_highlight_lines_hlids = []
    endif
    if !exists('b:auf_newadded_lines')
        let b:auf_newadded_lines = []
    endif
    if len(b:auf_highlight_lines_hlids)
        if !g:auf_highlight_on_bufenter
            call auf#util#logVerbose('AufBufReadPost: clearing highlights')
            call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
        endif
        return
    endif
    if g:auf_highlight_on_bufenter
        Auf
    else
        %call auf#format#TryAllFormatters(0, '')
    endif
    call auf#util#logVerbose('AufBufReadPost: END')
endfunction

" Save and recall window state to prevent vim from jumping to line 1: Beware
" that it should be done here due to <line1>,<line2> range.
command! -nargs=? -range=% -complete=filetype -bang -bar Auf
    \ let ww=winsaveview()|
    \ <line1>,<line2>call auf#format#TryAllFormatters(<bang>0, 'AufErrLine', <f-args>)|
    \ call winrestview(ww)
command! -nargs=0 -bar AufJIT call AufJit()

" Create commands for iterating through formatter list
command! AufNextFormatter call auf#format#NextFormatter()
command! AufPrevFormatter call auf#format#PreviousFormatter()
command! AufCurrFormatter call auf#format#CurrentFormatter()

command! AufShowDiff call auf#format#ShowDiff()
command! AufClearHi call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)

augroup Auf_Auto_Inserts
    autocmd!
    autocmd InsertEnter *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 |
        \   call auf#format#InsertModeOn() |
        \ endif
    autocmd InsertLeave *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 |
        \   call auf#format#InsertModeOff('AufChgLine', g:auf_changedline_pattern, 'AufErrLine') |
        \ endif
    autocmd CursorHold *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 |
        \   call auf#format#CursorHoldInNormalMode('AufChgLine', g:auf_changedline_pattern, 'AufErrLine') |
        \ endif
augroup END

augroup Auf_Auto_BufEvents
    autocmd!
    autocmd BufEnter *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 |
        \   call AufBufReadPost() |
        \ endif
    autocmd BufRead *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 &&
        \    g:auf_hijack_gq |
        \   setl formatexpr=AufFormatRange(v:lnum,v:lnum+v:count-1) |
        \ endif
    autocmd BufWritePre *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 |
        \   call AufJit() |
        \ endif
    autocmd BufWritePost *
        \ if stridx(g:auf_filetypes, ",".&ft.",") != -1 &&
        \    g:auf_highlight_errs |
        \   Auf |
        \ endif
    autocmd BufLeave *
        \ if exists('b:auf_highlight_lines_hlids') |
        \   call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids) |
        \ endif
    autocmd BufEnter *
        \ if exists('b:auf_highlight_lines_hlids') |
        \   call auf#util#highlights_On(b:auf_highlight_lines_hlids, 'AufErrLine') |
        \ endif
augroup END

