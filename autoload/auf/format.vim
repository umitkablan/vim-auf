if exists('g:loaded_auf_format_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_format_autoload = 1

function! s:setCache(fmtdef, idx, confpath)
    let [b:auffmt_definition, b:auffmt_current_idx] = [a:fmtdef, a:idx]
    let cpath = a:confpath
    if !len(cpath)
        let cpath = auf#util#CheckProbeFileUpRecursive(expand('%:p:h'),
                    \ get(a:fmtdef, 'probefiles', []))
    endif
    if !len(cpath)
        let confvar = 'auffmt_' . a:fmtdef['ID'] . '_config'
        let cpath = get(g:, confvar, '')
    endif
    let b:auf__formatprg_base = auf#registry#BuildCmdBaseFromDef(a:fmtdef, cpath)
endfunction

function! auf#format#GetCurrentFormatter()
    let [def, is_set] = [get(b:, 'auffmt_definition', {}), 0]
    if !empty(def) && exists('b:auffmt_current_idx')
        return [def, is_set]
    endif

    let is_set = 1
    if g:auf_probe_formatter
        let [i, def, confpath] = s:probeFormatter()
        if !empty(def)
            call auf#util#logVerbose('GetCurrentFormatter: Probed ' . def['ID']
                        \ . ' formatter at ' . i)
            call s:setCache(def, i, confpath)
            return [def, is_set]
        endif
    endif

    let varname = 'aufformatters_' . &ft
    let fmt_list = get(g:, varname, '')
    if type(fmt_list) == type('')
        let def = auf#registry#GetFormatterByIndex(&ft, 0)
        if empty(def)
            return [def, 0]
        endif
        call s:setCache(def, 0, '')
    elseif type(fmt_list) == type([])
        for i in range(0, len(fmt_list)-1)
            let id = fmt_list[i]
            call auf#util#logVerbose('GetCurrentFormatter: Cheking format definitions for ID:' . id)
            let def = auf#registry#GetFormatterByID(id, &ft)
            if !empty(def)
                call s:setCache(def, i, '')
                break
            endif
        endfor
    else
        call auf#util#echoErrorMsg('Supply a list in variable: g:' . varname)
    endif
    return [def, is_set]
endfunction

function! s:tryOneFormatter(line1, line2, fmtdef, overwrite, coward, synmatch)
    let [res, drift, resstr] = auf#format#FormatSource(a:line1, a:line2,
                                \ a:fmtdef, a:overwrite, a:coward, a:synmatch)
    if res > 1
        if b:auf__highlight__
            call auf#util#echoErrorMsg('Formatter "' . a:fmtdef['ID'] . '": ' . resstr)
        endif
        return 0
    elseif res == 0
        if b:auf__highlight__
            call auf#util#echoSuccessMsg(a:fmtdef['ID'] . ' Format PASSED ~' . drift)
        endif
        return 1
    elseif res == 1
        if b:auf__highlight__
            call auf#util#echoWarningMsg(a:fmtdef['ID'] . ' ~' . drift . ' ' . resstr)
        endif
        return 1
    endif
    return 0
endfunction

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! auf#format#TryAllFormatters(bang, synmatch, ...) range
    let [overwrite, ftype] = [a:bang, &ft] " a:0 ? a:1 : &filetype
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if empty(def)
        if is_set
        endif
        call auf#util#logVerbose('TryAllFormatters: No format definitions are'
                    \ .' defined for this type:' . ftype . ', fallback..')
        if overwrite
            call auf#format#Fallback(1, a:firstline, a:lastline)
        endif
        return 0
    endif

    let [coward, current_idx, fmtidx, tot] = [
                \ 0, b:auffmt_current_idx, b:auffmt_current_idx,
                \ auf#registry#FormattersCount(ftype)]
    if b:auffmt_definition != {}
        if s:tryOneFormatter(a:firstline, a:lastline, b:auffmt_definition,
                    \ overwrite, coward, a:synmatch)
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
            if current_idx == fmtidx
                call auf#util#echoErrorMsg('Tried all definitions and no suitable #' . fmtidx)
                break
            endif
        endif
        call s:setCache(def, fmtidx, '')
        call auf#util#logVerbose('TryAllFormatters: Trying definition in @'
                    \ . def['ID'])
        if s:tryOneFormatter(a:firstline, a:lastline, def, overwrite, coward,
                    \ a:synmatch)
            let b:auffmt_definition = def
            return 1
        else
            let fmtidx = (fmtidx + 1) % tot
            if fmtidx == current_idx
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

function! auf#format#Fallback(iserr, line1, line2)
    if exists('b:auf_remove_trailing_spaces') ? b:auf_remove_trailing_spaces
                \ : g:auf_remove_trailing_spaces
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

function! s:checkAllRmLinesEmpty(n, rmlines)
    let [rmcnt, emp] = [len(a:rmlines), 1]
    for i in range(0, a:n-1)
        if rmcnt > i && len(a:rmlines[i]) > 0
            let emp = 0
            break
        endif
    endfor
    return emp
endfunction

function! auf#format#evalApplyDif(line1, difpath, coward)
    let [hunks, tot_drift] = [0, 0]
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('evalApplyDif: diff line:' . linenr
                        \ . ' has zero change!')
            continue
        endif
        if a:coward
            if linenr < a:line1
                " if all those to-be-removed lines are empty then no need to be coward
                if !s:checkAllRmLinesEmpty(a:line1-linenr, rmlines)
                    call auf#util#logVerbose('evalApplyDif: COWARD ' . linenr
                                \ . ' - ' . a:line1 . '-' . linenr)
                    continue
                endif
            elseif linenr > a:line1
                break
            endif
        endif
        let linenr += tot_drift
        if prevcnt > 0 && curcnt > 0
            call auf#util#logVerbose('evalApplyDif: *replace* ' . linenr . ','
                        \ . prevcnt . ',' . curcnt)
            call auf#util#replaceLines(linenr, prevcnt, addlines)
        elseif prevcnt > 0
            call auf#util#logVerbose('evalApplyDif: *remove* ' . linenr . ','
                        \ . prevcnt . ',' . curcnt)
            call auf#util#removeLines(linenr, prevcnt)
        else
            call auf#util#logVerbose('evalApplyDif: *addline* ' . linenr . ','
                        \ . prevcnt . ',' . curcnt)
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

function! auf#format#doFormatSource(line1, line2, fmtdef, curfile,
            \ formattedf, difpath, synmatch, overwrite, coward)
    let [isoutf, cmd, isranged] = auf#registry#BuildCmdFullFromDef(a:fmtdef,
                \ b:auf__formatprg_base.' '.shellescape(a:curfile), a:formattedf,
                \ a:line1, a:line2)
    call auf#util#logVerbose('doFormatSource: isOutF:' . isoutf . ' isRanged:' . isranged)
    let [out, err, sherr] = auf#util#execSystem(cmd)
    call auf#util#logVerbose('doFormatSource: shErr:' . sherr . ' err:' . err)
    if sherr != 0
        return [2, sherr, 0, err]
    endif
    if !isoutf
        call writefile(split(out, '\n'), a:formattedf)
    endif

    let isfull = auf#util#isFullSelected(a:line1, a:line2)
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:curfile,
                \ a:formattedf, a:difpath)
    call auf#util#logVerbose('doFormatSource: isFull:' . isfull
                \ . ' isSame:' . issame . ' isRanged:' . isranged
                \ . ' shErr:' . sherr . ' err:' . err)
    if issame
        call auf#util#logVerbose('doFormatSource: no difference')
        let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(
                    \ a:synmatch, b:auf_highlight_lines_hlids,
                    \ a:line1, a:line2)
        return [0, 0, 0, err]
    elseif err
        return [3, sherr, 0, err]
    endif
    call auf#util#logVerbose_fileContent('doFormatSource: difference'
                \ . ' detected:' . a:difpath, a:difpath, 'doFormatSource: ========')
    if !isranged && !isfull
        let [err, sherr] = auf#diff#filterPatchLinesRanged(g:auf_filterdiffcmd,
                    \ a:line1, a:line2, a:curfile, a:difpath)
        call auf#util#logVerbose_fileContent('doFormatSource:' .
                    \ 'err: ' . err . ' shErr: ' . sherr .
                    \ ' difference after filter:' . a:difpath,
                    \ a:difpath, 'doFormatSource: ========')
        if sherr != 0
            return [2, sherr, 0, err]
        endif
    endif

    " call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    if !a:overwrite
        " let b:auf_highlight_lines_hlids = auf#util#highlightLines(auf#diff#parseChangedLines(a:difpath), a:synmatch)
        let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(
                    \ a:synmatch, b:auf_highlight_lines_hlids,
                    \ a:line1, a:line2)
        let b:auf_highlight_lines_hlids = auf#util#highlightLinesRanged(
                    \ b:auf_highlight_lines_hlids,
                    \ auf#diff#parseChangedLines(a:difpath), a:synmatch)
        return [1, 0, 0, err]
    endif

    " call feedkeys("\<C-G>u", 'n')

    let [hunks, drift] = auf#format#evalApplyDif(a:line1, a:difpath, a:coward)
    if hunks == -1
        return [4, 0, 0, err]
    endif
    let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(a:synmatch,
                \ b:auf_highlight_lines_hlids, a:line1, a:line2)
    let b:auf_newadded_lines = auf#util#clearHighlightsInRange(a:synmatch,
                \ b:auf_newadded_lines, a:line1, a:line2)
    if drift != 0
        call auf#util#driftHighlightsAfterLine(b:auf_highlight_lines_hlids,
                    \ a:line1, drift, '', '')
    endif

    call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    return [1, 0, drift, err]
endfunction

function! s:populateShadowIfAbsent() abort
    if exists('b:auf_shadowpath')
        return
    endif

    let b:auf_shadowpath = expand('%:p:h') . g:auf_tempnames_prefix . expand('%:t') . '.aufshadow0'
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
endfunction

function! auf#format#FormatSource(line1, line2, fmtdef, overwrite, coward, synmatch)
    call auf#util#logVerbose('FormatSource: ' . a:line1 . ',' . a:line2 . ' '
                \ . a:fmtdef['ID'] . ' ow:' . a:overwrite . ' SynMatch:' . a:synmatch)
    if !exists('b:auf_difpath')
        let b:auf_difpath = expand('%:p:h') . g:auf_tempnames_prefix . expand('%:t') . '.aufdiff'
    endif
    call s:populateShadowIfAbsent()
    let formattedf = tempname()
    call auf#util#logVerbose('FormatSource: origTmp:' . b:auf_shadowpath .
                \ ' formTmp:' . formattedf)

    let resstr = ''
    let [res, sherr, drift, err] = auf#format#doFormatSource(a:line1, a:line2,
                \ a:fmtdef, b:auf_shadowpath, formattedf, b:auf_difpath,
                \ a:synmatch, a:overwrite, a:coward)
    call auf#util#logVerbose('FormatSource: res:' . res . ' ShErr:' . sherr)
    if res == 0 "No diff found
    elseif res == 2 "Format program error
        let resstr = 'formatter failed(' . sherr . '): ' . err
    elseif res == 3 "Diff program error
        let resstr = 'diff failed(' . sherr . '): ' . err
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

function! s:doFormatLines(ln1, ln2, synmatch)
    call auf#util#logVerbose('s:doFormatLines: ' . a:ln1 . '-' . a:ln2)
    let [res, drift] = [1, 0]
    if exists('b:auffmt_definition')
        let [coward, overwrite] = [1, 1]
        let [res, drift, resstr] = auf#format#FormatSource(a:ln1, a:ln2,
                    \ b:auffmt_definition, overwrite, coward, a:synmatch)
        call auf#util#logVerbose('s:doFormatLines: result:' . res . ' ~' . drift)
        if len(resstr)
            if b:auf__highlight__
                if res > 1
                    call auf#util#echoErrorMsg(b:auffmt_definition['ID']
                                \ . ' fail:' . res . ' ' . resstr)
                else
                    call auf#util#echoWarningMsg(b:auffmt_definition['ID']
                                \ . '> ' . resstr)
                endif
            endif
            let [res, drift] = [0, 0]
        else
            let res = 1
        endif
    else
        call auf#util#logVerbose('doFormatLines: formatter program could not be found')
        call auf#format#Fallback(1, a:ln1, a:ln2)
    endif

    let b:auf_newadded_lines = auf#util#clearHighlightsInRange(
                \ a:synmatch, b:auf_newadded_lines, a:ln1, a:ln2)
    return [res, drift]
endfunction

function! s:jitAddedLines(synmatch)
    if !len(b:auf_newadded_lines)
        return 0
    endif

    let [tot_drift, res, msg, lines] = [0, 1, '', [b:auf_newadded_lines[0][0]]]
    for i in range(1, len(b:auf_newadded_lines)-1)
        let [linenr, curcnt] = [b:auf_newadded_lines[i][0], len(lines)]
        if lines[curcnt-1] == linenr-1 " successive lines to be appended
            let lines += [linenr]
        else
            let ln0 = lines[0]
            let [res, drift] = s:doFormatLines(ln0+tot_drift,
                        \ ln0+curcnt-1+tot_drift, a:synmatch)
            if !res
                break
            endif
            let msg .= '' . ln0 . ':' . curcnt . '~' . drift . ' /'
            let [tot_drift, lines] = [tot_drift+drift, [linenr]]
        endif
    endfor
    if len(lines) && res
        let [ln0, curcnt] = [lines[0], len(lines)]
        let [res, drift] = s:doFormatLines(ln0+tot_drift,
                    \ ln0+curcnt-1+tot_drift, a:synmatch)
        if res
            let msg .= '' . ln0 . ':' . curcnt . '~' . drift . ' /'
            let tot_drift += drift
        endif
    endif
    if res
        let msg .= '#' . tot_drift
        if exists('b:auffmt_definition')
            call auf#util#echoSuccessMsg(b:auffmt_definition['ID'] . '> ' . msg)
        else
            call auf#util#echoWarningMsg('Fallback> ' . msg)
        endif
    endif
endfunction

function! s:jitDiffedLines(synmatch)
    call writefile(getline(1, '$'), b:auf_shadowpath)
    let [tot_drift, res, msg] = [0, 1, '']
    if !filereadable(expand('%:p'))
        let [res, drift] = s:doFormatLines(1, line('$'), a:synmatch)
        let msg .= '1-$:' . '~' . drift . ' /'
    else
        let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, expand('%:p'),
                    \ b:auf_shadowpath, b:auf_difpath)
        if issame
        elseif err
            call auf#util#logVerbose('jitDiffedLines: diff error '
                        \ . err . '/'. sherr . ' diff current')
            return 2
        endif
        call auf#util#logVerbose_fileContent('jitDiffedLines: diff done file:'
                    \ . b:auf_difpath, b:auf_difpath, 'jitDiffedLines: ========')
        for [linenr, addlines, rmlines] in auf#diff#parseHunks(b:auf_difpath)
            let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
            if prevcnt == 0 && curcnt == 0
                call auf#util#echoErrorMsg('jitDiffedLines: invalid hunk-lines:'
                            \ . linenr . '-' . prevcnt . ',' . curcnt)
                continue
            endif
            if curcnt > 0
                let [ln0, ln1] = [linenr+tot_drift, linenr+curcnt-1+tot_drift]
                call auf#util#logVerbose('jitDiffedLines: hunk-lines:' . ln0 . '-' . ln1)
                let [res, drift] = s:doFormatLines(ln0, ln1, a:synmatch)
                if !res
                    break
                endif
                let msg .= '' . ln0 . ':' . curcnt . '~' . drift . ' /'
                if res > 1
                    break
                endif
                let tot_drift += drift
            endif
        endfor
    endif
    if res
        let msg .= '#' . tot_drift
        if exists('b:auffmt_definition')
            call auf#util#echoSuccessMsg(b:auffmt_definition['ID'] . '> ' . msg)
        else
            call auf#util#echoWarningMsg('Fallback> ' . msg)
        endif
    endif
endfunction

function! auf#format#justInTimeFormat(synmatch)
    call auf#util#logVerbose('justInTimeFormat: trying..')
    let [l, c] = [line('.'), col('.')]
    try
        " Diff current state with on-the-disk saved state - tracked changes
        " might be out of sync due to uncatchable normal mode edits, so
        " re-diffing whole is better idea
        call s:jitDiffedLines(a:synmatch) " call s:jitAddedLines(a:synmatch)
        call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    catch /.*/
        call auf#util#echoErrorMsg('Exception: ' . v:exception)
    finally
        keepjumps silent execute 'normal! ' . l . 'gg'
        if c-col('.') > 0
            keepjumps silent execute 'normal! ' . (c-col('.')) . 'l'
        endif
    endtry
    call auf#util#logVerbose('justInTimeFormat: DONE')
endfunction

function! auf#format#InsertModeOn()
    call auf#util#logVerbose('InsertModeOn: Start')
    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    call s:populateShadowIfAbsent()
    call auf#util#logVerbose('InsertModeOn: End')
endfunction

function! s:driftHighlights(synmatch_chg, lnregexp_chg, synmatch_err, oldf,
            \ newf, difpath)
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:oldf,
                \ a:newf, a:difpath)
        if issame
        call auf#util#logVerbose('s:driftHighlights: no edit has detected - no diff')
        return 0
    elseif err
        call auf#util#echoErrorMsg('s:driftHighlights: diff error '
                    \ . err . '/'. sherr)
        return 2
    endif
    call auf#util#logVerbose_fileContent('s:driftHighlights: diff done file:'
                \ . b:auf_difpath, b:auf_difpath, 's:driftHighlights: ========')
    let b:auf__highlight__ = 1
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('s:driftHighlights: invalid hunk-lines:'
                        \ . linenr . '-' . prevcnt . ',' . curcnt)
                continue
            endif
        let drift = curcnt - prevcnt
        call auf#util#logVerbose('s:driftHighlights: line:' . linenr . ' cur:'
                    \ . curcnt . ' prevcnt:' . prevcnt . ' drift:' . drift)
        if prevcnt > 0
            let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(
                        \ a:synmatch_err, b:auf_highlight_lines_hlids,
                        \ linenr, linenr + prevcnt - 1)
            let b:auf_newadded_lines = auf#util#clearHighlightsInRange(
                        \ a:synmatch_chg, b:auf_newadded_lines,
                        \ linenr, linenr + prevcnt - 1)
        endif
        if drift != 0
            call auf#util#driftHighlightsAfterLine(b:auf_highlight_lines_hlids,
                        \ linenr+1, drift, '', '')
            call auf#util#driftHighlightsAfterLine(b:auf_newadded_lines, linenr+1,
                        \ drift, a:synmatch_chg, g:auf_changedline_pattern)
        endif
        if curcnt > 0
            let b:auf_newadded_lines = auf#util#addHighlightNewLines(
                        \ b:auf_newadded_lines, linenr, linenr+curcnt-1,
                        \ a:synmatch_chg, a:lnregexp_chg)
        endif
    endfor
endfunction

function! auf#format#InsertModeOff(synmatch_chg, lnregexp_chg, synmatch_err)
    call auf#util#logVerbose('InsertModeOff: Start')
    let b:auf_linecnt_last = line('$')
    let tmpcurfile = expand('%:p:h') . g:auf_tempnames_prefix . expand('%:t') . '.aufshadow2'
    if tmpcurfile ==# b:auf_shadowpath
        let tmpcurfile = expand('%:p:h') . g:auf_tempnames_prefix . expand('%:t') . '.aufshadow3'
    endif
    try
        call writefile(getline(1, '$'), tmpcurfile)
        call s:driftHighlights(a:synmatch_chg, a:lnregexp_chg, a:synmatch_err,
                    \ b:auf_shadowpath, tmpcurfile, b:auf_difpath)
        let [b:auf_shadowpath, tmpcurfile] = [tmpcurfile, b:auf_shadowpath]
    catch /.*/
        call auf#util#echoErrorMsg('InsertModeOff: Exception: ' . v:exception)
    finally
        call delete(tmpcurfile)
    endtry
    if b:auf__highlight__
        call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch_err)
    endif
    call auf#util#logVerbose('InsertModeOff: End')
endfunction

function! auf#format#CursorHoldInNormalMode(synmatch_chg, lnregexp_chg, synmatch_err)
    call auf#util#logVerbose('CursorHoldInNormalMode: Start')
    if !&modified
        if !exists('b:auf_linecnt_last')
            let b:auf_linecnt_last = line('$')
        endif
        call auf#util#logVerbose('CursorHoldInNormalMode: NoModif End')
        return
    endif
    if b:auf_linecnt_last == line('$')
        call auf#util#logVerbose('CursorHoldInNormalMode: NoLineDiff End')
        return
    endif
    call s:populateShadowIfAbsent()
    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    call auf#format#InsertModeOff(a:synmatch_chg, a:lnregexp_chg, a:synmatch_err)
    call auf#util#logVerbose('CursorHoldInNormalMode: End')
endfunction

" Functions for iterating through list of available formatters
function! auf#format#NextFormatter()
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if is_set
        if empty(def)
            call auf#util#echoErrorMsg('No formatter could be found for:' . &ft)
            return
        endif
        call auf#util#echoSuccessMsg('Selected formatter: #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif

    let n = auf#registry#FormattersCount(&ft)
    if n < 2
        call auf#util#echoSuccessMsg('++Selected formatter (same): #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif
    let idx = (b:auffmt_current_idx + 1) % n
    let def = auf#registry#GetFormatterByIndex(&ft, idx)
    if empty(def)
        call auf#util#echoErrorMsg('Cannot select next')
        return
    endif
    call s:setCache(def, idx, '')
    call auf#util#echoSuccessMsg('++Selected formatter: #'
                \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
endfunction

function! auf#format#PreviousFormatter()
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if is_set
        if empty(def)
            call auf#util#echoErrorMsg('No formatter could be found for:' . &ft)
            return
        endif
        call auf#util#echoSuccessMsg('Selected formatter: #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif

    let n = auf#registry#FormattersCount(&ft)
    if n < 2
        call auf#util#echoSuccessMsg('--Selected formatter (same): #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif
    let idx = b:auffmt_current_idx - 1
    if idx < 0
        let idx = n - 1
    endif
    let def = auf#registry#GetFormatterByIndex(&ft, idx)
    if empty(def)
        call auf#util#echoErrorMsg('Cannot select previous')
        return
    endif
    call s:setCache(def, idx, '')
    call auf#util#echoSuccessMsg('--Selected formatter: #'
                \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
endfunction

function! auf#format#CurrentFormatter()
    let [def, is_set] = auf#format#GetCurrentFormatter()
    if empty(def)
        call auf#util#echoErrorMsg('No formatter could be found for:' . &ft)
        if is_set
        endif
        return
    endif
    call auf#util#echoSuccessMsg('Current formatter: #' . b:auffmt_current_idx
                \ . ': ' . def['ID'])
endfunction

function! auf#format#BufDeleted(bufnr)
    let path = getbufvar(a:bufnr, 'auf_shadowpath', '')
    if path !=# ''
        call delete(path)
    endif
    " call setbufvar(a:bufnr, 'auf_shadowpath', '')
    let path = getbufvar(a:bufnr, 'auf_difpath', '')
    if path !=# ''
        call delete(path)
    endif
    " call setbufvar(a:bufnr, 'auf_difpath', '')
endfunction

function! auf#format#ShowDiff()
    if exists('b:auf_difpath')
        exec 'sp ' . b:auf_difpath
        setl buftype=nofile ft=diff bufhidden=wipe ro nobuflisted noswapfile nowrap
    endif
endfunction

augroup AUF_BufDel
    autocmd!
    autocmd BufDelete * call auf#format#BufDeleted(expand('<abuf>'))
    autocmd BufUnload * call auf#format#BufDeleted(bufnr(expand('<afile>')))
augroup END

function! s:probeFormatter()
    call auf#util#logVerbose('s:probeFormatter: Started')
    let varname = 'aufformatters_' . &ft
    let [fmt_list, def, i, probefile] = [get(g:, varname, ''), {}, 0, '']
    if type(fmt_list) == type('')
        call auf#util#logVerbose('s:probeFormatter: Check probe files of all defined formatters')
        while 1
            let def = auf#registry#GetFormatterByIndex(&ft, i)
            if empty(def)
                break
            endif
            let probefile = auf#util#CheckProbeFileUpRecursive(expand('%:p:h'),
                        \ get(def, 'probefiles', []))
            if len(probefile)
                break
            endif
            let [i, def] = [i+1, {}]
        endwhile
    else
        for i in range(0, len(fmt_list)-1)
            let id = fmt_list[i]
            call auf#util#logVerbose('s:probeFormatter: Cheking format definitions for ID:' . id)
            let def = auf#registry#GetFormatterByID(id, &ft)
            if empty(def)
                continue
            endif
            let probefile = auf#util#CheckProbeFileUpRecursive(expand('%:p:h'),
                        \ get(def, 'probefiles', []))
            if len(probefile)
                break
            endif
            let def = {}
        endfor
    endif
    call auf#util#logVerbose('s:probeFormatter: Ended: i:' . i . ' def:'
                \ . get(def, 'ID', '_VOID_'))
    return [empty(def) ? -1 : i, def, probefile]
endfunction

