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

function! s:gq_vim_internal(ln1, ln2) abort
    let tmpe = &l:formatexpr
    setl formatexpr=
    let dif = a:ln2 - a:ln1
    execute 'keepjumps! norm! ' . a:ln1 . 'Ggq' . (dif>0 ? (dif.'j') : 'gq')
    let &l:formatexpr = tmpe
endfunction

function! AufFormatRange(line1, line2) abort
    call auf#util#logVerbose('AufFormatRange: ' . a:line1 . '-' . a:line2)
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if empty(def)
        if is_set
        endif
        call auf#util#echoErrorMsg('gq: no available formatter: Fallbacking..')
        call auf#format#Fallback(1, a:line1, a:line2)
        call s:gq_vim_internal(a:line1, a:line2)
    else
        let [overwrite, coward] = [1, 0]
        let [res, drift, resstr] = auf#format#TryOneFormatter(a:line1, a:line2, def,
                    \ overwrite, coward, 'AufErrLine')
        if res > 1
            call auf#util#echoErrorMsg('gq Fallbacking: ' . resstr)
            call s:gq_vim_internal(a:line1, a:line2)
        else
            call auf#util#echoSuccessMsg('gq fine:' . resstr . ' ~' . drift)
        endif
    endif
    call auf#util#logVerbose('AufFormatRange: DONE')
endfunction

function! AufJit() abort
    try
        let jit = 0
        if !&modified
        elseif !g:auf_jitformat
            call auf#util#echoErrorMsg('Jit> JITing is disabled GLOBALLY')
        elseif exists('b:auf_jitformat') && !b:auf_jitformat
            call auf#util#echoErrorMsg('Jit> JITing is disabled locally')
        elseif v:cmdbang
            call auf#util#echoErrorMsg('Jit> Did NOT JIT due to w! bang - accepted as is..')
        else
            let jit = 1
        endif

        if !jit
            call auf#util#clearAllHighlights(b:auf_newadded_lines)
            let b:auf_newadded_lines = []
        else
            let b:auf__highlight__ = 1
            call auf#format#justInTimeFormat('AufErrLine')
        endif
    catch /.*/
        call auf#util#echoErrorMsg('Exception: ' . v:exception)
    endtry
endfunction

function! AufBufNewFile() abort
    call auf#util#logVerbose('AufBufNewFile: START')
    let b:auf__highlight__ = 1
    call AufBufReadPost()
    call auf#util#logVerbose('AufBufNewFile: END')
endfunction

function! AufBufReadPost() abort
    call auf#util#logVerbose('AufBufReadPost: START')
    if !exists('b:auf_highlight_lines_hlids')
        let b:auf_highlight_lines_hlids = []
    endif
    if !exists('b:auf_newadded_lines')
        let b:auf_newadded_lines = []
    endif
    if !exists('b:auf__highlight__')
        let b:auf__highlight__ = g:auf_highlight_on_bufenter
    endif
    if !exists('b:auf_difpath')
        let b:auf_difpath = expand('%:p:h') . g:auf_tempnames_prefix . expand('%:t') . '.aufdiff0'
    endif

    if b:auf__highlight__
        %call auf#format#TryAllFormatters(0, 'AufErrLine')
    endif
    if &textwidth
        if g:auf_highlight_longlines == 1
            let &colorcolumn = &textwidth
        elseif g:auf_highlight_longlines == 2
            let w:auf__longlines_hl_id__ = matchadd(
                \ g:auf_highlight_longlines_syntax, '\%>'.(&tw+1).'v.\+', -1)
        endif
    endif
    call auf#util#logVerbose('AufBufReadPost: END')
endfunction

function! AufInfo() abort
    let [i, formatters] = [0, '']
    while 1
        let def = auf#registry#GetFormatterByIndex(&ft, i)
        if empty(def)
            break
        endif
        if index(def['filetypes'], &ft) > -1
            let formatters .= get(def, 'ID', '') . ', '
        endif
        let i += 1
    endwhile
    echomsg 'Formatters: [' . formatters[:-3] . ']'
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
command! AufNextFormatter call auf#format#NextFormatter()
command! AufPrevFormatter call auf#format#PreviousFormatter()
command! AufCurrFormatter call auf#format#CurrentFormatter()
command! AufInfo call AufInfo()
command! -nargs=0 AufDisable
    \ let b:auf_disable=1 |
    \ call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids) |
    \ call auf#util#clearAllHighlights(b:auf_newadded_lines) |
    \ let b:auf_newadded_lines = []
command! -nargs=0 AufEnable unlet! b:auf_disable

command! AufShowDiff call auf#format#ShowDiff()
command! AufClearHi
    \ call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids) |
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
    return (g:auf_filetypes ==# '*' && &buftype ==# '')
            \ || stridx(g:auf_filetypes, ','.&ft.',') != -1
endfunction

augroup Auf_Auto_Inserts
    autocmd!
    autocmd InsertEnter *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call auf#format#InsertModeOn() |
        \ endif
    autocmd InsertLeave *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call auf#format#InsertModeOff('AufChgLine', g:auf_changedline_pattern, 'AufErrLine') |
        \ endif
    autocmd CursorHold *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call auf#format#CursorHoldInNormalMode('AufChgLine', g:auf_changedline_pattern, 'AufErrLine') |
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
        \   setl formatexpr=AufFormatRange(v:lnum,v:lnum+v:count-1) |
        \ endif
    autocmd BufWritePre *
        \ if !exists('b:auf_disable') && s:isAufFiletype() |
        \   call AufJit() |
        \ endif
    autocmd BufWritePost *
        \ if !exists('b:auf_disable') && s:isAufFiletype() && g:auf_rescan_on_writepost |
        \   call auf#util#logVerbose('Auf: BufWritePost: Rescanning') |
        \   Auf |
        \ endif
augroup END

call auf#registry#LoadAllFormatters()

