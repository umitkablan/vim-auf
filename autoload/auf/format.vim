if exists('g:loaded_auf_format_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_format_autoload = 1

function! s:gq_vim_internal(ln1, ln2) abort
    let tmpe = &l:formatexpr
    setl formatexpr=
    let dif = a:ln2 - a:ln1
    execute 'keepjumps norm! ' . a:ln1 . 'Ggq' . (dif>0 ? (dif.'j') : 'gq')
    let &l:formatexpr = tmpe
endfunction

function! auf#format#gq(line1, line2) abort
    call auf#util#logVerbose('auf#format#gq: ' . a:line1 . '-' . a:line2)
    let [def, is_set] = auf#formatters#getCurrent()
    if empty(def)
        if is_set
        endif
        call auf#util#echoErrorMsg('auf#format#gq: no available formatter: Fallbacking..')
        call s:fallbackFormat(1, a:line1, a:line2)
        call s:gq_vim_internal(a:line1, a:line2)
    else
        let [overwrite, coward, synmatch] = [1, 0, 'AufErrLine']
        let [res, drift, resstr, _] = s:formatSource(a:line1, a:line2, def,
                                                \ overwrite, coward, synmatch)
        if res > 1
            call auf#util#echoErrorMsg('auf#format#gq: Fallbacking: ' . resstr)
            call s:gq_vim_internal(a:line1, a:line2)
        else
            call auf#util#echoSuccessMsg('auf#format#gq fine:' . resstr . ' ~' . drift)
        endif
    endif
    call auf#util#logVerbose('auf#format#gq: DONE')
endfunction

function! auf#format#getDiffOfFormatted(ln1, ln2) abort
    call auf#util#logVerbose('auf#format#getDiffOfFormatted: ' . a:ln1 . '-' . a:ln2)
    let [def, is_set] = auf#formatters#getCurrent()
    if empty(def)
        if is_set
        endif
        return []
    endif
    let [overwrite, coward, synmatch] = [0, 0, '']
    let [res, drift, resstr, diflines] = s:formatSource(a:ln1, a:ln2, def,
                                                \ overwrite, coward, synmatch)
    call auf#util#logVerbose('auf#format#getDiffOfFormatted: DONE')
    return diflines
endfunction

function! auf#format#JIT(synmatch) abort
    call auf#util#logVerbose('auf#format#JIT: trying..')
    let [l, c] = [line('.'), col('.')]
    let [shadowpath, difpath] = [tempname(), tempname()]
    try
        " Diff current state with on-the-disk saved state - tracked changes
        " might be out of sync due to uncatchable normal mode edits, so
        " re-diffing whole is better idea
        call writefile(getline(1, '$'), shadowpath)
        call s:jitDiffedLines(a:synmatch, shadowpath, difpath) " call s:jitAddedLines(a:synmatch)
        call delete(shadowpath)
    catch /.*/
        call auf#util#echoErrorMsg('Exception: ' . v:exception)
    finally
        silent execute 'keepjumps normal! ' . l . 'gg'
        if c-col('.') > 0
            silent execute 'keepjumps normal! ' . (c-col('.')) . 'l'
        endif
        call delete(shadowpath)
        call delete(difpath)
    endtry
    call auf#util#logVerbose('auf#format#JIT: DONE')
endfunction

function! s:tryOneFormatter(line1, line2, fmtdef, overwrite, coward, synmatch,
                                                        \ print_status) abort
    let [res, drift, resstr, _] = s:formatSource(a:line1, a:line2, a:fmtdef,
                                        \ a:overwrite, a:coward, a:synmatch)
    if res > 1
        if a:print_status
            call auf#util#echoErrorMsg('Formatter "' . a:fmtdef['ID'] . '": ' . resstr)
        endif
        return 0
    elseif res == 0
        if a:print_status
            call auf#util#echoSuccessMsg(a:fmtdef['ID'] . ' Format PASSED ~' . drift)
        endif
        return 1
    elseif res == 1
        if a:print_status
            call auf#util#echoWarningMsg(a:fmtdef['ID'] . ' ~' . drift . ' ' . resstr)
        endif
        return 1
    endif
    return 0
endfunction

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! auf#format#TryAllFormatters(bang, synmatch, ...) range abort
    call auf#util#logVerbose('TryAllFormatters: bang:' . a:bang . ' synmatch:'
                                                            \ . a:synmatch)
    let [overwrite, ftype] = [a:bang, &ft] " a:0 ? a:1 : &filetype
    let [def, is_set] = auf#formatters#getCurrent()
    if empty(def)
        if is_set
        endif
        call auf#util#logVerbose('TryAllFormatters: No format definitions are'
                    \ .' defined for this type:' . ftype . ', fallback..')
        if overwrite
            call s:fallbackFormat(1, a:firstline, a:lastline)
        endif
        return 0
    endif

    let [coward, current_idx, fmtidx] = [0, b:auffmt_current_idx, b:auffmt_current_idx]
    let tot = auf#registry#FormattersCount(ftype)
    if b:auffmt_definition != {}
        if s:tryOneFormatter(a:firstline, a:lastline, b:auffmt_definition,
                        \ overwrite, coward, a:synmatch, b:auf__highlight__)
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
        call auf#formatters#setCurrent(def, fmtidx, '')
        call auf#util#logVerbose('TryAllFormatters: Trying definition in @' . def['ID'])
        if s:tryOneFormatter(a:firstline, a:lastline, def, overwrite, coward,
                                            \ a:synmatch, b:auf__highlight__)
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
        call s:fallbackFormat(1, a:firstline, a:lastline)
    endif
    return 0
endfunction

function! auf#format#ScanForDeepIndentation(ln1, ln2, maxindent)
    let [spaced, tabbed] = ['^' . repeat(repeat(' ', &l:shiftwidth), a:maxindent),
                                    \ '^' . repeat('	', a:maxindent)]
    let [i, ret] = [0, []]
    for ln in getline(a:ln1, a:ln2)
        let i += 1
        if ln =~# spaced || ln =~# tabbed
            call add(ret, i)
        endif
    endfor
    return ret
endfunction

function! s:fallbackFormat(iserr, line1, line2) abort
    if exists('b:auf_remove_trailing_spaces') ? b:auf_remove_trailing_spaces
                \ : g:auf_remove_trailing_spaces
        call auf#util#logVerbose('Fallback: Removing trailing whitespace...')
        silent execute 'keepjumps ' a:line1 . ',' . a:line2 . 'substitute/\s\+$//e'
        call histdel('search', -1)
    endif
    if exists('b:auf_retab') ? b:auf_retab == 1 : g:auf_retab == 1
        call auf#util#logVerbose('Fallback: Retabbing...')
        silent execute 'keepjumps ' . a:line1 ',' . a:line2 . 'retab'
    endif
    if exists('b:auf_autoindent') ? b:auf_autoindent : g:auf_autoindent
        call auf#util#logVerbose('Fallback: Autoindenting...')
        let dif = a:line2 - a:line1
        silent execute 'keepjumps norm! ' . a:line1 . 'G=' . (dif > 0 ? (dif.'j') : '=')
    endif
    if a:iserr && g:auf_fallback_func !=# ''
        call auf#util#logVerbose('Fallback: Calling fallback function defined by user...')
        if call(g:auf_fallback_func, [])
            call auf#util#logVerbose('Fallback: g:auf_fallback_func returned non-zero - stop FB')
            return
        endif
    endif
endfunction

function! s:checkAllRmLinesEmpty(n, rmlines) abort
    let [rmcnt, emp] = [len(a:rmlines), 1]
    for i in range(0, a:n-1)
        if rmcnt > i && len(a:rmlines[i]) > 0
            let emp = 0
            break
        endif
    endfor
    return emp
endfunction

function! s:applyDiff(line1, difpath, coward) abort
    let [hunks, tot_drift] = [0, 0]
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        call auf#util#logVerbose('applyDiff: ln:' . linenr . ' +:'
                                    \ . len(addlines) . ' -:' . len(rmlines))
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('applyDiff: diff line:' . linenr
                                                    \ . ' has zero change!')
            continue
        endif
        if a:coward
            if linenr < a:line1
                " if all those to-be-removed lines are empty then no need to be coward
                if !s:checkAllRmLinesEmpty(a:line1-linenr, rmlines)
                    call auf#util#logVerbose('applyDiff: COWARD ' . linenr
                                        \ . ' - ' . a:line1 . '-' . linenr)
                    continue
                endif
            endif
        endif
        let linenr += tot_drift
        if prevcnt > 0 && curcnt > 0
            call auf#util#logVerbose('applyDiff: *replace* ' . linenr . ','
                                                \ . prevcnt . ',' . curcnt)
            call auf#util#replaceLines(linenr, prevcnt, addlines)
        elseif prevcnt > 0
            call auf#util#logVerbose('applyDiff: *remove* ' . linenr . ','
                                                \ . prevcnt . ',' . curcnt)
            call auf#util#removeLines(linenr, prevcnt)
        else
            call auf#util#logVerbose('applyDiff: *addline* ' . linenr . ','
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

function! s:executeFormatter(ln1, ln2, fmtdef, curf, fmtedf) abort
    let [isoutf, cmd, isranged] = auf#registry#BuildCmdFullFromDef(a:fmtdef,
                \ b:auf__formatprg_base.' '.shellescape(a:curf), a:fmtedf,
                \ a:ln1, a:ln2)
    call auf#util#logVerbose('executeFormatter: isOutF:' . isoutf . ' isRanged:' . isranged)
    let [out, err, sherr] = auf#util#execSystem(cmd)
    call auf#util#logVerbose('executeFormatter: shErr:' . sherr . ' err:' . err)
    if sherr != 0
        return [sherr, err]
    endif
    if !isoutf
        call writefile(split(out, '\n'), a:fmtedf)
    endif
    return [0, isranged]
endfunction

function! s:doFormatSource(line1, line2, fmtdef, curfile, formattedf, difpath,
                                        \ synmatch, overwrite, coward) abort
    let [sherr, isranged] = s:executeFormatter(a:line1, a:line2, a:fmtdef,
                                                    \ a:curfile, a:formattedf)
    if sherr
        return [2, sherr, 0, isranged]
    endif

    let isfull = auf#util#isFullSelected(a:line1, a:line2)
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:curfile,
                                                    \ a:formattedf, a:difpath)
    call auf#util#logVerbose('doFormatSource: isFull:' . isfull
                            \ . ' isSame:' . issame . ' isRanged:' . isranged
                            \ . ' shErr:' . sherr . ' err:' . err)
    if issame
        call auf#util#logVerbose('doFormatSource: no difference')
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
                                    \ 'err:' . err . ' shErr:' . sherr .
                                    \ ' difference after filter:' . a:difpath,
                                    \ a:difpath, 'doFormatSource: ========')
        if sherr != 0
            return [2, sherr, 0, err]
        endif
    endif

    if !a:overwrite
        if !isfull
            return [1, 0, 0, err]
        endif
        call auf#util#cleanAllHLIDs(w:, 'auf_highlight_lines_hlids')
        let b:auf_err_lnnr_list = auf#diff#parseChangedLines(a:difpath)
        if a:synmatch !=# ''
            let w:auf_highlight_lines_hlids =
                \ auf#util#highlightLinesRanged(w:auf_highlight_lines_hlids,
                                            \ b:auf_err_lnnr_list, a:synmatch)
        endif
        return [1, 0, 0, err]
    endif
    " call feedkeys("\<C-G>u", 'n')

    let [hunks, drift] = s:applyDiff(a:line1, a:difpath, a:coward)
    if hunks == -1
        return [4, 0, 0, err]
    endif
    return [1, 0, drift, err]
endfunction

function! s:formatSource(line1, line2, fmtdef, overwrite, coward, synmatch) abort
    call auf#util#logVerbose('formatSource: ' . a:line1 . ',' . a:line2 . ' '
            \ . a:fmtdef['ID'] . ' ow:' . a:overwrite . ' SynMatch:' . a:synmatch)
    let [formattedf, shadowpath, difpath] = [tempname(), tempname(), tempname()]
    let diflines = []
    try
        call writefile(getline(1, '$'), shadowpath)
        call auf#util#logVerbose('formatSource: origTmp:' . shadowpath
                                                \ . ' formTmp:' . formattedf)

        let [resstr, clear] = ['', 0]
        let [res, sherr, drift, err] = s:doFormatSource(a:line1, a:line2,
                                \  a:fmtdef, shadowpath, formattedf, difpath,
                                \  a:synmatch, a:overwrite, a:coward)
        call auf#util#logVerbose('formatSource: res:' . res . ' ShErr:' . sherr)
        if res == 0 "No diff found
            let clear = 1
        elseif res == 2 "Format program error
            let resstr = 'formatter failed(' . sherr . '): ' . err
        elseif res == 3 "Diff program error
            let resstr = 'diff failed(' . sherr . '): ' . err
        elseif res == 4 "Refuse to format - coward mode on
            let [resstr, res] = ['cowardly refusing - it touches more lines than edited', 1]
            let diflines = readfile(difpath)
        else
            let clear = 1
            let diflines = readfile(difpath)
        endif
        if clear && a:overwrite
            let w:auf_highlight_lines_hlids =
                        \ auf#util#clearHighlightsInRange(a:synmatch,
                                \ w:auf_highlight_lines_hlids, a:line1, a:line2)
            let w:auf_newadded_lines_hlids =
                        \ auf#util#clearHighlightsInRange(a:synmatch,
                                \ w:auf_newadded_lines_hlids, a:line1, a:line2)
        endif
        if drift != 0
            let b:auf_err_lnnr_list =
                    \ auf#util#driftHighlightsAfterLine(
                        \ w:auf_highlight_lines_hlids, a:line1, drift, '', '')
            let b:auf_new_lnnr_list =
                    \ auf#util#driftHighlightsAfterLine(
                        \ w:auf_newadded_lines_hlids, a:line1, drift, '', '')
        endif
        call auf#util#logVerbose('formatSource: res:' . res . ' drift:' . drift
                                                        \ . ' resstr:' . resstr)
    catch /.*/
        call auf#util#echoErrorMsg('Auf> s:formatSource: ' . v:exception)
    finally
        call delete(formattedf)
        call delete(shadowpath)
        call delete(difpath)
    endtry
    return [res, drift, resstr, diflines]
endfunction

function! s:formatOrFallback(ln1, ln2, synmatch) abort
    call auf#util#logVerbose('s:formatOrFallback: ' . a:ln1 . '-' . a:ln2)
    let [res, drift] = [1, 0]
    if exists('b:auffmt_definition')
        let [coward, overwrite] = [1, 1]
        let [res, drift, resstr] = s:formatSource(a:ln1, a:ln2,
                        \ b:auffmt_definition, overwrite, coward, a:synmatch)
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
        call auf#util#logVerbose('s:formatOrFallback: formatter program could not be found')
        call s:fallbackFormat(1, a:ln1, a:ln2)
    endif

    let w:auf_newadded_lines_hlids = auf#util#clearHighlightsInRange(a:synmatch,
                                    \ w:auf_newadded_lines_hlids, a:ln1, a:ln2)
    call auf#util#logVerbose('s:formatOrFallback: result:' . res . ' ~' . drift)
    return [res, drift]
endfunction

function! s:jitAddedLines(synmatch) abort
    if !len(b:auf_new_lnnr_list)
        return 0
    endif

    let [tot_drift, res, msg, lines] = [0, 1, '', [b:auf_new_lnnr_list[0]]]
    for i in range(1, len(b:auf_new_lnnr_list)-1)
        let [linenr, curcnt] = [b:auf_new_lnnr_list[i], len(lines)]
        if lines[curcnt-1] == linenr-1 " successive lines to be appended
            let lines += [linenr]
        else
            let ln0 = lines[0]
            let [res, drift] = s:formatOrFallback(ln0+tot_drift,
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
        let [res, drift] = s:formatOrFallback(ln0+tot_drift,
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

function! s:jitDiffedLines(synmatch, shadowpath, difpath) abort
    let [tot_drift, res, msg] = [0, 1, '']
    if !filereadable(expand('%:p'))
        let [res, drift] = s:formatOrFallback(1, line('$'), a:synmatch)
        let msg .= '1-$:' . '~' . drift . ' /'
    else
        let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, expand('%:p'),
                                                    \ a:shadowpath, a:difpath)
        if issame
        elseif err
            call auf#util#logVerbose('jitDiffedLines: diff error '
                                        \ . err . '/'. sherr . ' diff current')
            return 2
        endif
        call auf#util#logVerbose_fileContent('jitDiffedLines: diff done file:'
                        \ . a:difpath, a:difpath, 'jitDiffedLines: ========')
        for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
            call auf#util#logVerbose('s:jitDiffedLines: ln:' . linenr . ' +:'
                                    \ . len(addlines) . ' -:' . len(rmlines))
            let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
            if prevcnt == 0 && curcnt == 0
                call auf#util#echoErrorMsg('jitDiffedLines: invalid hunk-lines:'
                                    \ . linenr . '-' . prevcnt . ',' . curcnt)
                continue
            endif
            let drift = curcnt - prevcnt
            if curcnt > 0
                let [ln0, ln1] = [linenr+tot_drift, linenr+curcnt-1+tot_drift]
                call auf#util#logVerbose('jitDiffedLines: hunk-lines:' . ln0 . '-' . ln1)
                let [res, drift_] = s:formatOrFallback(ln0, ln1, a:synmatch)
                let msg .= '' . ln0 . ':' . curcnt . '~' . drift_ . '@' . res . ' /'
                let drift += drift_
            endif
            let tot_drift += drift
        endfor
    endif
    if res
        let msg .= '#' . tot_drift
        if exists('b:auffmt_definition')
            call auf#util#echoSuccessMsg(b:auffmt_definition['ID'] . ' JIT> ' . msg)
        else
            call auf#util#echoWarningMsg('Fallback JIT> ' . msg)
        endif
    endif
endfunction

