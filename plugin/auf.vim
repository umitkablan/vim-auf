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

function! AufFormatRange(line1, line2) abort
    call auf#util#logVerbose('AufFormatRange: ' . a:line1 . '-' . a:line2)
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if empty(def)
        if is_set
        endif
        call auf#util#echoErrorMsg('gq: no available formatter: Fallbacking..')
        call auf#format#Fallback(1, a:line1, a:line2)
        return
    endif
    let [overwrite, coward] = [1, 0]
    let [res, drift, resstr] = auf#format#TryFormatter(a:line1, a:line2, def,
                \ overwrite, coward, 'AufErrLine')
    if res > 1
        call auf#util#echoErrorMsg('gq error: ' . resstr)
    else
        call auf#util#echoSuccessMsg('gq fine:' . resstr . ' ~' . drift)
    endif
    call auf#util#logVerbose('AufFormatRange: DONE')
endfunction

function! AufJit() abort
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
            call auf#util#clearAllHighlights(b:auf_newadded_lines)
            let b:auf_newadded_lines = []
        else
            if &modified
                let b:auf__highlight__ = 1
                call auf#format#justInTimeFormat('AufErrLine')
            else
                call auf#util#clearAllHighlights(b:auf_newadded_lines)
                let b:auf_newadded_lines = []
            endif
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
        let b:auf_difpath = tempname()
    endif
    if b:auf__highlight__
        %call auf#format#TryAllFormatters(0, 'AufErrLine')
    else
        %call auf#format#TryAllFormatters(0, '')
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

augroup Auf_Auto_Inserts
    autocmd!
    autocmd InsertEnter *
        \ if (g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1 |
        \   call auf#format#InsertModeOn() |
        \ endif
    autocmd InsertLeave *
        \ if (g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1 |
        \   call auf#format#InsertModeOff('AufChgLine', g:auf_changedline_pattern, 'AufErrLine') |
        \ endif
    autocmd CursorHold *
        \ if (g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1 |
        \   call auf#format#CursorHoldInNormalMode('AufChgLine', g:auf_changedline_pattern, 'AufErrLine') |
        \ endif
augroup END

augroup Auf_Auto_BufEvents
    autocmd!
    autocmd BufNewFile *
        \ if (g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1 |
        \   call AufBufNewFile() |
        \ endif
    autocmd BufReadPost *
        \ if (g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1 |
        \   call AufBufReadPost() |
        \ endif
    autocmd BufRead *
        \ if ((g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1) &&
        \    g:auf_hijack_gq |
        \   setl formatexpr=AufFormatRange(v:lnum,v:lnum+v:count-1) |
        \ endif
    autocmd BufWritePre *
        \ if (g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1 |
        \   call AufJit() |
        \ endif
    autocmd BufWritePost *
        \ if ((g:auf_filetypes ==# '*' && &buftype ==# '') || stridx(g:auf_filetypes, ','.&ft.',') != -1) &&
        \    g:auf_rescan_on_writepost |
        \   call auf#util#logVerbose('Auf: BufWritePost: Rescanning') |
        \   Auf |
        \ endif
augroup END

call auf#registry#LoadAllFormatters()

