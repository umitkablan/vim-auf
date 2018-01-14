if exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_plugin = 1

runtime! plugin/auf_defaults.vim

if g:auf_diffcmd ==# '' || !executable(g:auf_diffcmd)
    augroup Auf_Error
        autocmd!
        autocmd VimEnter *
            \ call auf#util#echoErrorMsg("Can't start! \
                \Couldn't locate 'diff' program (defined in g:auf_diffcmd as '"
                \ . g:auf_diffcmd . "').")
    augroup END
    finish
endif
if g:auf_filterdiffcmd ==# '' || !executable(g:auf_filterdiffcmd)
    augroup Auf_Error
        autocmd!
        autocmd VimEnter *
            \ call auf#util#echoErrorMsg("Can't start! \
                \Couldn't locate 'filterdiff' program (defined in g:auf_filterdiffcmd as '"
                \ . g:auf_filterdiffcmd . "').")
    augroup END
    finish
endif

let g:auf_diffcmd .= ' -u '

function! s:hlChanges(prefix) abort
    let tmpcurfile = tempname()
    try
        call writefile(getline(1, '$'), tmpcurfile)
        call auf#highlights#relight('AufChgLine', g:auf_changedline_pattern,
                    \ 'AufErrLine', expand('%:.'), tmpcurfile, b:auf_difpath)
    catch /.*/
        call auf#util#echoErrorMsg(a:prefix . ': Exception: ' . v:exception)
    finally
        call delete(tmpcurfile)
    endtry
    if b:auf__highlight__
        call auf#util#highlights_On(w:auf_highlight_lines_hlids, 'AufErrLine')
    endif
endfunction

function! AufInsertModeOn() abort
    call auf#util#logVerbose('InsertModeOn: Start')
    call auf#util#highlights_Off(w:auf_highlight_lines_hlids)
    call auf#util#highlights_Off(w:auf_newadded_lines_hlids)
    call auf#util#logVerbose('InsertModeOn: End')
endfunction

function! AufInsertModeOff() abort
    call auf#util#logVerbose('AufInsertModeOff: Start')
    if b:changedtick == b:auf_changedtick_last
        if b:auf__highlight__
            call auf#util#highlights_On(w:auf_highlight_lines_hlids, 'AufErrLine')
            call auf#util#highlights_On(w:auf_newadded_lines_hlids, 'AufChgLine')
        endif
        call auf#util#logVerbose('AufInsertModeOff: NoChange End')
        return
    endif
    let b:auf_changedtick_last = b:changedtick
    call s:hlChanges('AufInsertModeOff')
    call auf#util#logVerbose('AufInsertModeOff: End')
endfunction

function! AufCursorHoldInNormalMode() abort
    call auf#util#logVerbose('CursorHoldInNormalMode: Start')
    if expand('%') ==# ''
        call auf#util#logVerbose('CursorHoldInNormalMode: NoBufferYet End')
        return
    endif
    if b:changedtick == b:auf_changedtick_last
        call auf#util#logVerbose('CursorHoldInNormalMode: NoChange End')
        return
    endif
    call auf#util#logVerbose('CursorHoldInNormalMode: Change: ' . b:auf_changedtick_last . '!=' . b:changedtick)
    let b:auf_changedtick_last = b:changedtick
    call s:hlChanges('CursorHoldInNormalMode')
    call auf#util#logVerbose('CursorHoldInNormalMode: End')
endfunction

function! AufBufNewFile() abort
    call auf#util#logVerbose('AufBufNewFile: START')
    let b:auf__highlight__ = 1
    call AufBufReadPost()
    call auf#util#logVerbose('AufBufNewFile: END')
endfunction

function! AufBufWinEnter() abort
    call auf#util#logVerbose('AufBufWinEnter: START')
    if !exists('b:auf_new_lnnr_list')
        let b:auf_new_lnnr_list = []
    endif
    if !exists('b:auf_err_lnnr_list')
        let b:auf_err_lnnr_list = []
    endif
    if !exists('b:auf__highlight__')
        let b:auf__highlight__ = g:auf_highlight_on_bufenter
    endif
    if !exists('b:auf_changedtick_last')
        let b:auf_changedtick_last = b:changedtick
    endif
    call auf#util#cleanAllHLIDs(w:, 'auf_highlight_lines_hlids')
    call auf#util#cleanAllHLIDs(w:, 'auf_newadded_lines_hlids')
    let w:auf_newadded_lines_hlids = auf#util#highlightLines(
                                        \ b:auf_new_lnnr_list, 'AufChgLine')
    if ! b:auf__highlight__
        call auf#util#logVerbose('AufBufWinEnter: NoHL END')
        return
    endif
    let w:auf_highlight_lines_hlids = auf#util#highlightLines(
                                        \ b:auf_err_lnnr_list, 'AufErrLine')
    call auf#util#logVerbose('AufBufWinEnter: END')
endfunction

function! AufBufReadPost() abort
    call auf#util#logVerbose('AufBufReadPost: START')
    call auf#util#cleanAllHLIDs(w:, 'auf_highlight_lines_hlids')
    call auf#util#cleanAllHLIDs(w:, 'auf_newadded_lines_hlids')
    if !exists('b:auf_difpath')
        let b:auf_difpath = expand('%:p:h') . g:auf_tempnames_prefix . expand('%:t') . '.aufdiff0'
    endif
    if !exists('b:auf__highlight__')
        let b:auf__highlight__ = g:auf_highlight_on_bufenter
    endif

    if &textwidth
        if g:auf_highlight_longlines == 1
            let &l:colorcolumn = &textwidth
        elseif g:auf_highlight_longlines == 2
            let w:auf__longlines_hl_id__ = matchadd(
                \ g:auf_highlight_longlines_syntax, '\%>'.(&tw+1).'v.\+', -1)
        endif
    endif

    let ww = winsaveview()
    %call auf#format#TryAllFormatters(0, b:auf__highlight__ ? 'AufErrLine': '')
    call winrestview(ww)

    call auf#util#logVerbose('AufBufReadPost: END')
endfunction

function! AufBufDeleted(bufnr) abort
    let path = getbufvar(a:bufnr, 'auf_difpath', '')
    if path !=# ''
        call delete(path)
    endif
    " call setbufvar(a:bufnr, 'auf_difpath', '')
endfunction

function! AufShowDiff() abort
    if exists('b:auf_difpath')
        exec 'sp ' . b:auf_difpath
        setl buftype=nofile ft=diff bufhidden=wipe ro nobuflisted noswapfile nowrap
    endif
endfunction

function! AufFormatJIT() abort
    try
        let jit = 0
        if !g:auf_jitformat
            call auf#util#echoErrorMsg('Jit> JITing is disabled GLOBALLY')
        elseif exists('b:auf_jitformat') && !b:auf_jitformat
            call auf#util#echoErrorMsg('Jit> JITing is disabled locally')
        elseif v:cmdbang
            call auf#util#echoErrorMsg('Jit> Did NOT JIT due to w! bang - accepted as is..')
        else
            let jit = 1
        endif

        if !jit
            call auf#util#cleanAllHLIDs(w:, 'auf_newadded_lines_hlids')
        else
            let b:auf__highlight__ = 1
            call auf#format#JIT('AufErrLine')
        endif
    catch /.*/
        call auf#util#echoErrorMsg('Exception: ' . v:exception)
    endtry
endfunction

" Save and recall window state to prevent vim from jumping to line 1: Beware
" that it should be done here due to <line1>,<line2> range.
command! -nargs=? -range=% -complete=filetype -bang -bar Auf
    \ let ww=winsaveview()|
    \ <line1>,<line2>call auf#format#TryAllFormatters(<bang>0, 'AufErrLine', <f-args>)|
    \ let b:auf__highlight__ = 1 |
    \ call winrestview(ww)
command! -nargs=0 -bar AufJIT call AufJit()

" Create commands for iterating through formatter list
command! AufNextFormatter call auf#formatters#setPrintNext()
command! AufPrevFormatter call auf#formatters#setPrintPrev()
command! AufCurrFormatter call auf#formatters#setPrintCurr()
command! AufInfo call auf#formatters#printAll()
command! -nargs=0 AufDisable
    \ let b:auf_disable=1 |
    \ call auf#util#cleanAllHLIDs(w:, 'auf_highlight_lines_hlids') |
    \ call auf#util#cleanAllHLIDs(w:, 'auf_newadded_lines_hlids') |
command! -nargs=0 AufEnable unlet! b:auf_disable

command! AufShowDiff call AufShowDiff()
command! AufClearHi
    \ call auf#util#cleanAllHLIDs(w:, 'auf_highlight_lines_hlids') |
    \ let b:auf__highlight__ = 0

let s:AufErrLineSynCmd = 'highlight def link AufErrLine ' . g:auf_showdiff_synmatch
let s:AufChgLineSynCmd = 'highlight def link AufChgLine ' . g:auf_changedline_synmatch
execute s:AufErrLineSynCmd
execute s:AufChgLineSynCmd

augroup Auf_Auto_Syntax
    autocmd!
    autocmd Syntax execute s:AufErrLineSynCmd
    autocmd Syntax execute s:AufChgLineSynCmd
augroup END

function! s:isAufFiletype() abort
    return (&readonly == 0 &&
        \  (g:auf_filetypes ==# '*' && &buftype ==# '')
        \   || stridx(g:auf_filetypes, ','.&ft.',') != -1)
endfunction

augroup Auf_Auto_Inserts
    autocmd!
    autocmd InsertEnter *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufInsertModeOn() |
        \ endif
    autocmd InsertLeave *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufInsertModeOff() |
        \ endif
    autocmd CursorHold *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufCursorHoldInNormalMode() |
        \ endif
augroup END

augroup Auf_Auto_BufEvents
    autocmd!
    autocmd BufNewFile *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufBufNewFile() |
        \ endif
    autocmd BufReadPost *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufBufReadPost() |
        \ endif
    autocmd BufRead *
        \ if s:isAufFiletype() && g:auf_hijack_gq |
        \   setl formatexpr=auf#format#gq(v:lnum,v:lnum+v:count-1) |
        \ endif
    autocmd BufWritePre *
        \ if !exists('b:auf_disable') && s:isAufFiletype() && &modified |
        \   call AufFormatJIT() |
        \ endif
    autocmd BufWritePost *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufBufReadPost() |
        \ endif
    autocmd BufWinEnter *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufBufWinEnter() |
        \ endif
    autocmd BufDelete * call AufBufDeleted(expand('<abuf>'))
    autocmd BufUnload * call AufBufDeleted(bufnr(expand('<afile>')))
augroup END

call auf#registry#LoadAllFormatters()

