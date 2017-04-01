if exists('g:loaded_auf_format_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_format_autoload = 1

function! auf#format#GetCurrentFormatter() abort
    let [def, is_set] = [get(b:, 'auffmt_definition', {}), 0]
    if empty(def) || !exists('b:auffmt_current_idx')
        let varname = 'aufformatters_' . &ft
        let fmt_list = get(b:, varname, get(g:, varname, ''))
        if type(fmt_list) == type('')
            let def = auf#registry#GetFormatterByIndex(&ft, 0)
            if empty(def)
                return [def, is_set]
            endif
            let [b:auffmt_definition, b:auffmt_current_idx, is_set] = [def, 0, 1]
        elseif type(fmt_list) == type([])
            for i in range(0, len(fmt_list)-1)
                let id = fmt_list[i]
                call auf#util#logVerbose('GetCurrentFormatter: Cheking format definitions for ID:' . id)
                let def = auf#registry#GetFormatterByID(id, &ft)
                if !empty(def)
                    let [b:auffmt_definition, b:auffmt_current_idx, is_set] = [def, i, 1]
                    break
                endif
            endfor
        else
            call auf#util#echoErrorMsg('Auf> Supply a list in variable: g:' . varname)
        endif
    endif
    return [def, is_set]
endfunction

function! s:tryFmtDefinition(line1, line2, fmtdef, overwrite, coward, synmatch) abort
    let [res, drift, resstr] = auf#format#TryFormatter(a:line1, a:line2, a:fmtdef, a:overwrite, a:coward, a:synmatch)
    if res > 1
        if b:auf__highlight__
            call auf#util#echoErrorMsg('Auf> Formatter "' . a:fmtdef['ID'] . '": ' . resstr)
        endif
        return 0
    elseif res == 0
        if b:auf__highlight__
            call auf#util#echoSuccessMsg('Auf> ' . a:fmtdef['ID'] . ' Format PASSED ~' . drift)
        endif
        return 1
    elseif res == 1
        if b:auf__highlight__
            call auf#util#echoWarningMsg('Auf> ' . a:fmtdef['ID'] . ' ~' . drift . ' ' . resstr)
        endif
        return 1
    endif
    return 0
endfunction

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! auf#format#TryAllFormatters(bang, synmatch, ...) range abort
    let [overwrite, ftype] = [a:bang, &ft] " a:0 ? a:1 : &filetype
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if empty(def)
        if is_set
        endif
        call auf#util#logVerbose('TryAllFormatters: No format definitions are defined for this type:' . ftype . ', fallback..')
        if overwrite
            call auf#format#Fallback(1, a:firstline, a:lastline)
        endif
        return 0
    endif

    if !exists('b:auffmt_definition')
        let b:auffmt_definition = def
    endif

    let [coward, fmtidx, tot] = [0, b:auffmt_current_idx, auf#registry#FormattersCount(ftype)]
    if b:auffmt_definition != {}
        if s:tryFmtDefinition(a:firstline, a:lastline, b:auffmt_definition, overwrite, coward, a:synmatch)
            return 1
        endif
        if tot < 2
            return 0
        endif
        unlet! b:auf__formatprg_base
        let fmtidx = (fmtidx + 1) % tot
    endif

    while 1
        let def = auf#registry#GetFormatterByIndex(ftype, fmtidx)
        if empty(def)
            if b:auffmt_current_idx == fmtidx
                call auf#util#echoErrorMsg('Auf> Tried all definitions and no suitable #' . fmtidx)
                break
            endif
        endif
        call auf#util#logVerbose('TryAllFormatters: Trying definition in @' . def['ID'])
        if s:tryFmtDefinition(a:firstline, a:lastline, def, overwrite, coward, a:synmatch)
            let b:auffmt_definition = def
            return 1
        else
            let fmtidx = (fmtidx + 1) % tot
            if fmtidx == b:auffmt_current_idx
                break
            endif
        endif
    endwhile

    call auf#util#logVerbose('TryAllFormatters: No format definitions were successful.')
    unlet! b:auffmt_definition
    if overwrite
        call auf#format#Fallback(1, a:firstline, a:lastline)
    endif
    return 0
endfunction

function! auf#format#Fallback(iserr, line1, line2) abort
    if exists('b:auf_remove_trailing_spaces') ? b:auf_remove_trailing_spaces : g:auf_remove_trailing_spaces
        call auf#util#logVerbose('Fallback: Removing trailing whitespace...')
        keepjumps execute a:line1 . ',' . a:line2 . 'substitute/\s\+$//e'
        call histdel('search', -1)
    endif
    if exists('b:auf_retab') ? b:auf_retab == 1 : g:auf_retab == 1
        call auf#util#logVerbose('Fallback: Retabbing...')
        keepjumps execute '' . a:line1 ',' . a:line2 . 'retab'
    endif
    if exists('b:auf_autoindent') ? b:auf_autoindent : g:auf_autoindent
        call auf#util#logVerbose('Fallback: Autoindenting...')
        let dif = a:line2 - a:line1
        keepjumps execute 'normal ' . a:line1 . 'G=' . (dif > 0 ? (dif.'j') : '=')
    endif
    if a:iserr && g:auf_fallback_func !=# ''
        call auf#util#logVerbose('Fallback: Calling fallback function defined by user...')
        if call(g:auf_fallback_func, [])
            call auf#util#logVerbose('Fallback: g:auf_fallback_func returned non-zero - stop FB')
            return
        endif
    endif
endfunction

function! s:formatSource(line1, line2, fmtdef, inpath, outpath) abort
    if !exists('b:auf__formatprg_base')
        let b:auf__formatprg_base = auf#registry#BuildCmdBaseFromDef(a:fmtdef)
    endif
    let [isoutf, cmd, isranged] = auf#registry#BuildCmdFullFromDef(a:fmtdef,
                \ b:auf__formatprg_base.' "'.a:inpath.'"', a:outpath, a:line1, a:line2)
    call auf#util#logVerbose('formatSource: isOutF:' . isoutf . ' Command:' . cmd . ' isRanged:' . isranged)
    if !isoutf
        let out = auf#util#execWithStdout(cmd)
        call writefile(split(out, '\n'), a:outpath)
    else
        let out = auf#util#execWithStderr(cmd)
    endif
    return [v:shell_error == 0, isranged, v:shell_error]
endfunction

function! s:checkAllRmLinesEmpty(n, rmlines) abort
    let [rmcnt, emp] = [len(a:rmlines), 1]
    for i in range(0, a:n-1)
        if rmcnt > i && len(a:rmlines[i]) > 0
            let emp = 0
            break
        endif
        let i += 1
    endfor
    return emp
endfunction

function! auf#format#evalApplyDif(line1, difpath, coward) abort
    let [hunks, tot_drift] = [0, 0]
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('Auf> evalApplyDif: diff line:' . linenr . ' has zero change!')
            continue
        endif
        if a:coward
            if linenr < a:line1
                " if all those to-be-removed lines are empty then no need to be coward
                if !s:checkAllRmLinesEmpty(a:line1-linenr, rmlines)
                    call auf#util#logVerbose('evalApplyDif: COWARD ' . linenr . ' - ' . a:line1 . '-' . linenr)
                    continue
                endif
            elseif linenr > a:line1
                break
            endif
        endif
        let linenr += tot_drift
        if prevcnt > 0 && curcnt > 0
            call auf#util#logVerbose('evalApplyDif: *replace* ' . linenr . ',' . prevcnt . ',' . curcnt)
            call auf#util#replaceLines(linenr, prevcnt, addlines)
        elseif prevcnt > 0
            call auf#util#logVerbose('evalApplyDif: *remove* ' . linenr . ',' . prevcnt . ',' . curcnt)
            call auf#util#removeLines(linenr, prevcnt)
        else
            call auf#util#logVerbose('evalApplyDif: *addline* ' . linenr . ',' . prevcnt . ',' . curcnt)
            call auf#util#addLines(linenr, addlines)
        endif
        let tot_drift += (curcnt - prevcnt)
        let hunks += 1
    endfor
    if !hunks && a:coward
        return [-1, 0]
    endif
    return [hunks, tot_drift]
endfunction

function! auf#format#evaluateFormattedToOrig(line1, line2, fmtdef, curfile, formattedf, difpath, synmatch, overwrite, coward) abort
    if a:overwrite
        call auf#format#Fallback(0, a:line1, a:line2)
    endif

    let [res, is_formatter_ranged, sherr] = s:formatSource(a:line1, a:line2, a:fmtdef, a:curfile, a:formattedf)
    call auf#util#logVerbose('evaluateFormattedToOrig: sourceFormetted shErr:' . sherr)
    if !res
        return [2, sherr, 0]
    endif

    let isfull = auf#util#isFullSelected(a:line1, a:line2)
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:curfile, a:formattedf, a:difpath)
    call auf#util#logVerbose('evaluateFormattedToOrig: isFull:' . isfull . ' isSame:' . issame
                \ . ' isRangedFormat:' . is_formatter_ranged . ' shErr:' . sherr)
    if issame
        call auf#util#logVerbose('evaluateFormattedToOrig: no difference')
        let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(a:synmatch, b:auf_highlight_lines_hlids,
                        \ a:line1, a:line2)
        return [0, 0, 0]
    elseif err
        return [3, sherr, 0]
    endif
    call auf#util#logVerbose_fileContent('evaluateFormattedToOrig: difference detected:' . a:difpath,
                \ a:difpath, 'evaluateFormattedToOrig: ========')
    if !is_formatter_ranged && !isfull
        call auf#diff#filterPatchLinesRanged(g:auf_filterdiffcmd, a:line1, a:line2, a:curfile, a:difpath)
        call auf#util#logVerbose_fileContent('evaluateFormattedToOrig: difference after filter:' . a:difpath,
                    \ a:difpath, 'evaluateFormattedToOrig: ========')
    endif

    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    if !a:overwrite
        let b:auf_highlight_lines_hlids = auf#util#highlightLines(auf#diff#parseChangedLines(a:difpath), a:synmatch)
        return [1, 0, 0]
    endif

    let [hunks, drift] = auf#format#evalApplyDif(a:line1, a:difpath, a:coward)
    if hunks == -1
        return [4, 0, 0]
    endif
    let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(a:synmatch, b:auf_highlight_lines_hlids,
                    \ a:line1, a:line2)
    if drift != 0
        call auf#util#driftHighlightsAfterLine(b:auf_highlight_lines_hlids, a:line1, drift, '', '')
    endif

    call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    return [1, 0, drift]
endfunction

function! auf#format#TryFormatter(line1, line2, fmtdef, overwrite, coward, synmatch) abort
    call auf#util#logVerbose('TryFormatter: ' . a:line1 . ',' . a:line2 . ' ' . a:fmtdef['ID'] .
                \ ' ow:' . a:overwrite . ' SynMatch:' . a:synmatch)
    if !exists('b:auf_difpath')
        let b:auf_difpath = tempname()
    endif
    if !exists('b:auf_shadowpath')
        let b:auf_shadowpath = tempname()
        call writefile(getline(1, '$'), b:auf_shadowpath)
    endif
    let formattedf = tempname()
    call auf#util#logVerbose('TryFormatter: origTmp:' . formattedf . ' formTmp:' . formattedf)

    let resstr = ''
    let [res, sherr, drift] = auf#format#evaluateFormattedToOrig(a:line1, a:line2, a:fmtdef, b:auf_shadowpath,
                \ formattedf, b:auf_difpath, a:synmatch, a:overwrite, a:coward)
    call auf#util#logVerbose('TryFormatter: res:' . res . ' ShErr:' . sherr)
    if res == 0 "No diff found
    elseif res == 2 "Format program error
        let resstr = 'formatter failed(' . sherr . ')'
    elseif res == 3 "Diff program error
        let resstr = 'diff failed(' . sherr . ')'
    elseif res == 4 "Refuse to format - coward mode on
        let [resstr, res] = ['cowardly refusing - it touches more lines than edited', 1]
    else
        if a:overwrite
            call writefile(getline(1, '$'), b:auf_shadowpath)
        endif
    endif

    call delete(formattedf)
    return [res, drift, resstr]
endfunction

function! s:doFormatLines(ln1, ln2, synmatch) abort
    call auf#util#logVerbose('s:doFormatLines: ' . a:ln1 . '-' . a:ln2)
    let drift = 0
    if exists('b:auffmt_definition')
        let [coward, overwrite] = [1, 1]
        let [res, drift, resstr] = auf#format#TryFormatter(a:ln1, a:ln2, b:auffmt_definition, overwrite, coward, a:synmatch)
        call auf#util#logVerbose('s:doFormatLines: result:' . res . ' ~' . drift)
        if res > 1
            if b:auf__highlight__
                call auf#util#echoErrorMsg('Auf> ' . b:auffmt_definition['ID'] . ' fail:' . res . ' ' . resstr)
            endif
            return [0, 0]
        elseif resstr !=# ''
            if b:auf__highlight__
                call auf#util#echoWarningMsg('Auf> ' . b:auffmt_definition['ID'] . '> ' . resstr)
            endif
            return [0, 0]
        endif
    else
        call auf#util#logVerbose('justInTimeFormat: formatter program could not be found')
        call auf#format#Fallback(1, a:ln1, a:ln2)
    endif

    let b:auf_newadded_lines =
                \ auf#util#clearHighlightsInRange(a:synmatch, b:auf_newadded_lines, a:ln1, a:ln2)
    call auf#util#clearAllHighlights(b:auf_newadded_lines)
    let b:auf_newadded_lines = []
    return [1, drift]
endfunction

function! auf#format#justInTimeFormat(synmatch) abort
    call auf#util#logVerbose('justInTimeFormat: trying..')
    if !len(b:auf_newadded_lines)
        return 0
    endif
    let [l, c] = [line('.'), col('.')]
    try
        let [tot_drift, res, msg, lines] = [0, 1, '', [b:auf_newadded_lines[0][0]]]
        for i in range(1, len(b:auf_newadded_lines)-1)
            let [linenr, curcnt] = [b:auf_newadded_lines[i][0], len(lines)]
            if lines[curcnt-1] == linenr-1 " successive lines to be appended
                let lines += [linenr]
            else
                let ln0 = lines[0]
                let [res, drift] = s:doFormatLines(ln0+tot_drift, ln0+curcnt-1+tot_drift, a:synmatch)
                if !res
                    break
                endif
                let msg .= '' . ln0 . ':' . curcnt . '~' . drift . ' /'
                let [tot_drift, lines] = [tot_drift+drift, [linenr]]
            endif
        endfor
        if len(lines) && res
            let [ln0, curcnt] = [lines[0], len(lines)]
            let [res, drift] = s:doFormatLines(ln0+tot_drift, ln0+curcnt-1+tot_drift, a:synmatch)
            if res
                let msg .= '' . ln0 . ':' . curcnt . '~' . drift . ' /'
                let tot_drift += drift
            endif
        endif
        if res
            let msg .= '#' . tot_drift
            if exists('b:auffmt_definition')
                call auf#util#echoSuccessMsg('Auf> ' . b:auffmt_definition['ID'] . '> ' . msg)
            else
                call auf#util#echoWarningMsg('Auf> Fallback> ' . msg)
            endif
        endif
        call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    catch /.*/
        call auf#util#echoErrorMsg('Auf> Exception: ' . v:exception)
    finally
        keepjumps silent execute 'normal! ' . l . 'gg'
        if c-col('.') > 0
            keepjumps silent execute 'normal! ' . (c-col('.')) . 'l'
        endif
    endtry
    return 0
endfunction

function! auf#format#InsertModeOn() abort
    call auf#util#logVerbose('InsertModeOn: Start')
    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    if !exists('b:auf_shadowpath')
        let b:auf_shadowpath = tempname()
        " Nonetheless writefile doesn't work when you get into insert via o
        " (start on new line) - it gives *getline* with newline NOT before
        let flpath = expand('%:.')
        " when buffer/file is created brand new, there is no readable file in
        " the filesystem; also tempname() doesn't create file
        if filereadable(flpath)
            call system('cp ' . flpath . ' ' . b:auf_shadowpath)
            " call writefile(getline(1, '$'), b:auf_shadowpath)
        else
            call writefile([], b:auf_shadowpath)
        endif
    endif
    call auf#util#logVerbose('InsertModeOn: End')
endfunction

function! s:driftHighlights(synmatch_chg, lnregexp_chg, synmatch_err, oldf, newf, difpath) abort
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:oldf, a:newf, a:difpath)
    if issame
        call auf#util#logVerbose('s:driftHighlights: no edit has detected - no diff')
        return 0
    elseif err
        call auf#util#echoErrorMsg('Auf> s:driftHighlights: diff error ' . err . '/'. sherr)
        return 2
    endif
    call auf#util#logVerbose_fileContent('s:driftHighlights: diff done file:' . b:auf_difpath,
                \ b:auf_difpath, 's:driftHighlights: ========')
    let b:auf__highlight__ = 1
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('Auf> s:driftHighlights: invalid hunk-lines:' .
                    \ linenr . '-' . prevcnt . ',' . curcnt)
            continue
        endif
        let drift = curcnt - prevcnt
        call auf#util#logVerbose('s:driftHighlights: line:' . linenr . ' cur:' . curcnt . ' prevcnt:'
                    \ . prevcnt . ' drift:' . drift)
        if prevcnt > 0
            let b:auf_highlight_lines_hlids =
                \ auf#util#clearHighlightsInRange(a:synmatch_err, b:auf_highlight_lines_hlids, linenr, linenr + prevcnt - 1)
            let b:auf_newadded_lines =
                \ auf#util#clearHighlightsInRange(a:synmatch_chg, b:auf_newadded_lines, linenr, linenr + prevcnt - 1)
        endif
        if drift != 0
            call auf#util#driftHighlightsAfterLine(b:auf_highlight_lines_hlids, linenr+1, drift, '', '')
            call auf#util#driftHighlightsAfterLine(b:auf_newadded_lines, linenr+1, drift, a:synmatch_chg, g:auf_changedline_pattern)
        endif
        if curcnt > 0
            let b:auf_newadded_lines =
                \ auf#util#addHighlightNewLines(b:auf_newadded_lines, linenr, linenr+curcnt-1, a:synmatch_chg, a:lnregexp_chg)
        endif
    endfor
endfunction

function! auf#format#InsertModeOff(synmatch_chg, lnregexp_chg, synmatch_err) abort
    call auf#util#logVerbose('InsertModeOff: Start')
    let b:auf_linecnt_last = line('$')
    let tmpcurfile = tempname()
    try
        call writefile(getline(1, '$'), tmpcurfile)
        call s:driftHighlights(a:synmatch_chg, a:lnregexp_chg, a:synmatch_err, b:auf_shadowpath, tmpcurfile, b:auf_difpath)
        let [b:auf_shadowpath, tmpcurfile] = [tmpcurfile, b:auf_shadowpath]
    catch /.*/
        call auf#util#echoErrorMsg('Auf> InsertModeOff: Exception: ' . v:exception)
    finally
        call delete(tmpcurfile)
    endtry
    if b:auf__highlight__
        call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch_err)
    endif
    call auf#util#logVerbose('InsertModeOff: End')
endfunction

function! auf#format#CursorHoldInNormalMode(synmatch_chg, lnregexp_chg, synmatch_err) abort
    call auf#util#logVerbose('CursorHoldInNormalMode: Start')
    if !&modified
        if !exists('b:auf_linecnt_last')
            let b:auf_linecnt_last = line('$')
        endif
        call auf#util#logVerbose('CursorHoldInNormalMode: NoModif End')
        return
    endif
    if !exists('b:auf_shadowpath')
        let b:auf_shadowpath = tempname()
        call system('cp ' . expand('%:.') . ' ' . b:auf_shadowpath)
    endif
    if b:auf_linecnt_last == line('$')
        call auf#util#logVerbose('CursorHoldInNormalMode: NoLineDiff End')
        return
    endif
    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    call auf#format#InsertModeOff(a:synmatch_chg, a:lnregexp_chg, a:synmatch_err)
    call auf#util#logVerbose('CursorHoldInNormalMode: End')
endfunction

" Functions for iterating through list of available formatters
function! auf#format#NextFormatter() abort
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if is_set
        if empty(def)
            call auf#util#echoErrorMsg('Auf> No formatter could be found for:' . &ft)
            return
        endif
        call auf#util#echoSuccessMsg('Auf> Selected formatter: #' . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
    else
        let n = auf#registry#FormattersCount(&ft)
        if n < 2
            call auf#util#echoSuccessMsg('Auf> ++Selected formatter (same): #' . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
            return
        endif
        let idx = (b:auffmt_current_idx + 1) % n
        let def = auf#registry#GetFormatterByIndex(&ft, idx)
        if empty(def)
            call auf#util#echoErrorMsg('Auf> Cannot select next')
            return
        endif
        let [b:auffmt_definition, b:current_formatter_index] = [def, idx]
        call auf#util#echoSuccessMsg('Auf> ++Selected formatter: #' . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
    endif
endfunction

function! auf#format#PreviousFormatter() abort
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if is_set
        if empty(def)
            call auf#util#echoErrorMsg('Auf> No formatter could be found for:' . &ft)
            return
        endif
        call auf#util#echoSuccessMsg('Auf> Selected formatter: #' . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
    else
        let n = auf#registry#FormattersCount(&ft)
        if n < 2
            call auf#util#echoSuccessMsg('Auf> --Selected formatter (same): #' . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
            return
        endif
        let idx = b:auffmt_current_idx - 1
        if idx < 0
            let idx = n - 1
        endif
        let def = auf#registry#GetFormatterByIndex(&ft, idx)
        if empty(def)
            call auf#util#echoErrorMsg('Auf> Cannot select previous')
            return
        endif
        let [b:auffmt_definition, b:current_formatter_index] = [def, idx]
    endif
    call auf#util#echoSuccessMsg('Auf> --Selected formatter: #' . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
endfunction

function! auf#format#CurrentFormatter() abort
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if empty(def)
        call auf#util#echoErrorMsg('Auf> No formatter could be found for:' . &ft)
        if is_set
        endif
        return
    endif
    call auf#util#echoSuccessMsg('Auf> Current formatter: #' . b:auffmt_current_idx . ': ' . def['ID'])
endfunction

function! auf#format#BufDeleted(bufnr) abort
    let l:nr = str2nr(a:bufnr)
    if bufexists(l:nr) && !buflisted(l:nr)
        return
    endif
    let l:difpath = getbufvar(l:nr, 'auf_difpath')
    if l:difpath !=# ''
        call delete(l:difpath)
    endif
    call setbufvar(l:nr, 'auf_difpath', '')
    let shadowpath = getbufvar(l:nr, 'auf_shadowpath')
    if shadowpath !=# ''
        call delete(shadowpath)
    endif
    call setbufvar(l:nr, 'auf_shadowpath', '')
endfunction

function! auf#format#ShowDiff() abort
    if exists('b:auf_difpath')
        exec 'sp ' . b:auf_difpath
        setl buftype=nofile ft=diff bufhidden=wipe ro nobuflisted noswapfile nowrap
    endif
endfunction

augroup AUF_BufDel
    autocmd!
    autocmd BufDelete * call auf#format#BufDeleted(expand('<abuf>'))
augroup END
