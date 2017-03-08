if exists('g:loaded_auf_format_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_format_autoload = 1

" Function for finding the formatters for this filetype
" Result is stored in b:formatters
function! auf#format#find_formatters(...)
    " Extract filetype to be used
    let ftype = a:0 ? a:1 : &filetype
    " Support composite filetypes by replacing dots with underscores
    let compoundtype = substitute(ftype, '[.]', '_', 'g')
    if ftype =~? '[.]'
        " Try all super filetypes in search for formatters in a sane order
        let ftypes = [compoundtype] + split(ftype, '[.]')
    else
        let ftypes = [compoundtype]
    endif

    " Detect configuration for all possible ftypes
    let b:formatters = []
    for supertype in ftypes
        let formatters_var = 'b:aufformatters_' . supertype
        if !exists(formatters_var)
            let formatters_var = 'g:aufformatters_' . supertype
        endif
        if !exists(formatters_var)
            call auf#util#echoErrorMsg('Auf: No formatters defined for SuperType:' . supertype)
        else
            let formatters = eval(formatters_var)
            if type(formatters) != type([])
                call auf#util#echoErrorMsg('Auf: ' . formatters_var . ' is not a list')
            else
                let b:formatters = b:formatters + formatters
            endif
        endif
    endfor

    if len(b:formatters) == 0
        call auf#util#echoErrorMsg("Auf: No formatters defined for FileType:'" . ftype . "'")
        return 0
    endif
    return 1
endfunction

function! auf#format#getCurrentProgram() abort
    if !exists('b:formatprg')
        let [fmt_var, fmt_prg] = auf#util#getFormatterAtIndex(b:current_formatter_index)
        if fmt_prg ==# ''
            call auf#util#echoErrorMsg("No format definition found in '" . fmt_var . "'")
            return ''
        endif
        let b:formatprg = fmt_prg
    endif
    return b:formatprg
endfunction

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! auf#format#TryAllFormatters(bang, synmatch, ...) range
    " Make sure formatters are defined and detected
    if !call('auf#format#find_formatters', a:000)
        call auf#util#logVerbose('TryAllFormatters: No format definitions are defined for this FileType')
        call auf#format#Fallback()
        return 0
    endif

    " Make sure index exist and is valid
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    if b:current_formatter_index >= len(b:formatters)
        let b:current_formatter_index = 0
    endif

    " Try all formatters, starting with selected one
    let formatter_index = b:current_formatter_index

    if !has('eval')
        call auf#util#echoErrorMsg('AutoFormat ERROR: vim has no support for eval (check :version output for +eval) - REQUIRED!')
        return 1
    endif

    let overwrite = a:bang
    let coward = 0

    while 1
        let [fmt_var, fmt_prg] = auf#util#getFormatterAtIndex(formatter_index)
        if fmt_prg ==# ''
            call auf#util#echoErrorMsg("No format definition found in '" . fmt_var . "'")
            return 0
        endif
        let b:formatprg = fmt_prg

        call auf#util#logVerbose("TryAllFormatters: Trying definition in '" . fmt_var)
        let [res, drift, resstr] = auf#format#TryFormatter(a:firstline, a:lastline, fmt_prg, overwrite, coward, a:synmatch)
        if res > 1
            call auf#util#echoErrorMsg('Auf> Formatter #' . formatter_index . ':' . fmt_var . ' ' . resstr)
            let formatter_index = (formatter_index + 1) % len(b:formatters)
        elseif res == 0
            call auf#util#echoSuccessMsg('Auf> ' . fmt_var . ' Format PASSED ~' . drift)
            return 1
        elseif res == 1
            call auf#util#echoSuccessMsg('Auf> ' . fmt_var . ' ~' . drift . ' ' . resstr)
            return 1
        endif

        if formatter_index == b:current_formatter_index
            call auf#util#logVerbose('TryAllFormatters: No format definitions were successful.')
            " Tried all formatters, none worked
            call auf#format#Fallback(a:firstline, a:lastline)
            return 0
        endif
    endwhile
endfunction

function! auf#format#Fallback(line1, line2)
    if exists('b:auf_retab') ? b:auf_retab == 1 : g:auf_retab == 1
        call auf#util#logVerbose('Fallback: Retabbing...')
        keepjumps execute '' . a:line1 ',' . a:line2 . 'retab'
    endif
    if exists('b:auf_autoindent') ? b:auf_autoindent == 1 : g:auf_autoindent == 1
        call auf#util#logVerbose('Fallback: Autoindenting...')
        " Autoindent code
        keepjumps execute 'normal ' . a:line1 . 'G=' . (a:line2 - a:line1 + 1) . 'j'
    endif
endfunction

function! auf#format#formatSource(line1, line2, formatprg, inpath, outpath) abort
    let [isoutf, cmd, isranged] = auf#util#parseFormatPrg(a:formatprg, a:inpath, a:outpath, a:line1, a:line2)
    call auf#util#logVerbose('formatSource: isOutF:' . isoutf . ' Command:' . cmd . ' isRanged:' . isranged)
    if !isoutf
        let out = auf#util#execWithStdout(cmd)
        call writefile(split(out, '\n'), a:outpath)
    else
        let out = auf#util#execWithStderr(cmd)
    endif
    return [v:shell_error == 0, isranged, v:shell_error]
endfunction

function! auf#format#evalApplyDif(line1, difpath, coward) abort
    let [hunks, tot_drift] = [0, 0]
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('evalApplyDif: diff line:' . linenr . ' has zero change!')
            continue
        endif
        if linenr < a:line1 && a:coward && (prevcnt > 0 && len(rmlines[0]) > 0)
            call auf#util#logVerbose('evalApplyDif: COWARD ' . linenr . ' - ' . a:line1 . '-' . len(rmlines[0]))
            return [-1, 0]
        endif
        if prevcnt > 0 && curcnt > 0
            call auf#util#logVerbose('evalApplyDif: *replace* ' . (linenr + tot_drift) . ',' . prevcnt . ',' . curcnt)
            call auf#util#replaceLines(linenr + tot_drift, prevcnt, addlines)
        elseif prevcnt > 0
            call auf#util#logVerbose('evalApplyDif: *remove* ' . (linenr + tot_drift) . ',' . prevcnt . ',' . curcnt)
            call auf#util#removeLines(linenr + tot_drift, prevcnt)
        else
            call auf#util#logVerbose('evalApplyDif: *addline* ' . (linenr + tot_drift) . ',' . prevcnt . ',' . curcnt)
            call auf#util#addLines(linenr + tot_drift, addlines)
        endif
        let tot_drift += (curcnt - prevcnt)
        let hunks += 1
    endfor
    return [hunks, tot_drift]
endfunction

function! auf#format#evaluateFormattedToOrig(line1, line2, formatprg, curfile, formattedf, difpath, synmatch, overwrite, coward)
    if a:overwrite && g:auf_remove_trailing_spaces
        keepjumps execute  a:line1 . ',' . a:line2 . 'substitute/\s\+$//e'
        call histdel('search', -1)
    endif

    call writefile(getline(1, '$'), a:curfile)
    let [res, is_formatter_ranged, sherr] = auf#format#formatSource(a:line1, a:line2, a:formatprg, a:curfile, a:formattedf)
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

    let b:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(a:synmatch, b:auf_highlight_lines_hlids,
                    \ a:line1, a:line2)
    let [hunks, drift] = auf#format#evalApplyDif(a:line1, a:difpath, a:coward)
    if hunks == -1
        return [4, 0, 0]
    endif
    if drift != 0
        call auf#util#driftHighlightsAfterLine_nolight(b:auf_highlight_lines_hlids, a:line1, drift)
    endif

    call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    return [1, 0, drift]
endfunction

function! auf#format#TryFormatter(line1, line2, formatprg, overwrite, coward, synmatch)
    call auf#util#logVerbose('TryFormatter: ' . a:line1 . ',' . a:line2 . ' ' . a:formatprg .
                \ ' ow:' . a:overwrite . ' SynMatch:' . a:synmatch)
    let [tmpf0path, tmpf1path] = [tempname(), tempname()]
    call auf#util#logVerbose('TryFormatter: origTmp:' . tmpf0path . ' formTmp:' . tmpf1path)

    if !exists('b:auf_difpath')
        let b:auf_difpath = tempname()
    endif

    let resstr = ''
    let [res, sherr, drift] = auf#format#evaluateFormattedToOrig(a:line1, a:line2, a:formatprg, tmpf0path,
                \ tmpf1path, b:auf_difpath, a:synmatch, a:overwrite, a:coward)
    call auf#util#logVerbose('TryFormatter: res:' . res . ' ShErr:' . sherr)
    if res == 0 "No diff found
    elseif res == 2 "Format program error
        let resstr = 'formatter failed(' . sherr . ')'
    elseif res == 3 "Diff program error
        let resstr = 'diff failed(' . sherr . ')'
    elseif res == 4 "Refuse to format - coward mode on
        let [resstr, res] = ['cowardly refusing - it touches more lines than edited', 1]
    else
        if a:overwrite && exists('b:auf_shadowpath')
            call writefile(getline(1, '$'), b:auf_shadowpath)
        endif
    endif

    call delete(tmpf0path)
    call delete(tmpf1path)
    return [res, drift, resstr]
endfunction

function! auf#format#justInTimeFormat(synmatch) abort
    call auf#util#get_verbose()
    if !exists('b:formatprg')
        call auf#format#find_formatters()
    endif
    if !exists('b:formatprg')
        call auf#util#logVerbose('justInTimeFormat: formatter program could not be found')
        return 1
    endif
    if !exists('b:auf_difpath')
        let b:auf_difpath = tempname()
    endif

    let tmpcurfile = tempname()
    call auf#util#logVerbose('justInTimeFormat: trying..')
    try
        call writefile(getline(1, '$'), tmpcurfile)
        let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, expand('%:.'), tmpcurfile, b:auf_difpath)
        if issame
            call auf#util#logVerbose('justInTimeFormat: no edit has detected - no diff')
            return 0
        elseif err
            call auf#util#logVerbose('justInTimeFormat: diff error ' . err . '/'. sherr . ' diff current')
            return 2
        endif
        call auf#util#logVerbose_fileContent('justInTimeFormat: diff done file:' . b:auf_difpath, b:auf_difpath,
                    \ 'justInTimeFormat: ========')
        let [coward, overwrite, tot_drift, res] = [1, 1, 0, 1]
        for [linenr, addlines, rmlines] in auf#diff#parseHunks(b:auf_difpath)
            let [prevcnt, curcnt, drift] = [len(rmlines), len(addlines), 0]
            if prevcnt == 0 && curcnt == 0
                call auf#util#echoErrorMsg('justInTimeFormat: invalid hunk-lines:' . linenr . '-' . prevcnt . ',' . curcnt)
                continue
            endif
            if curcnt > 0
                let [ln0, ln1] = [linenr+tot_drift, linenr+curcnt-1+tot_drift]
                call auf#util#logVerbose('justInTimeFormat: hunk-lines:' . ln0 . '-' . ln1)
                let [res, drift, resstr] = auf#format#TryFormatter(ln0, ln1, b:formatprg, overwrite, coward, a:synmatch)
                call auf#util#logVerbose('justInTimeFormat: result:' . res . ' ~' . drift)
                if res > 1
                    call auf#util#echoErrorMsg('AufJIT> ' . b:formatters[b:current_formatter_index] . ' fail:' . res . ' ' . resstr)
                    break
                endif
            endif
            let tot_drift += drift
        endfor
        if res
            call auf#util#echoSuccessMsg('AufJIT> ' . b:formatters[b:current_formatter_index] . ' SUCCESS!')
        endif
        call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    catch /.*/
        call auf#utils#echoErrorMsg('AufJIT> Exception: ' . v:exception)
    finally
        call auf#util#logVerbose('justInTimeFormat: deleting temporary-current-buffer')
        call delete(tmpcurfile)
    endtry
    return 0
endfunction

function! auf#format#InsertModeOn()
    call auf#util#logVerbose('InsertModeOn: Start')
    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    if !exists('b:auf_shadowpath')
        let b:auf_shadowpath = tempname()
        " Nonetheless writefile doesn't work when you get into insert via o
        " (start on new line) - it gives *getline* with newline NOT before
        call system('cp ' . expand('%:.') . ' ' . b:auf_shadowpath)
        " call writefile(getline(1, '$'), b:auf_shadowpath)
    endif
    call auf#util#logVerbose('InsertModeOn: End')
endfunction

function! s:driftHighlights(synmatch, oldf, newf, difpath) abort
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:oldf, a:newf, a:difpath)
    if issame
        call auf#util#logVerbose('s:driftHighlights: no edit has detected - no diff')
        return 0
    elseif err
        call auf#util#echoErrorMsg('s:driftHighlights: diff error ' . err . '/'. sherr . ' diff current')
        return 2
    endif
    call auf#util#logVerbose_fileContent('s:driftHighlights: diff done file:' . b:auf_difpath,
                \ b:auf_difpath, 's:driftHighlights: ========')
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('s:driftHighlights: invalid hunk-lines:' .
                    \ linenr . '-' . prevcnt . ',' . curcnt)
            continue
        endif
        let drift = curcnt - prevcnt
        call auf#util#logVerbose('s:driftHighlights: line:' . linenr . ' cur:' . curcnt . ' prevcnt:'
                    \ . prevcnt . ' drift:' . drift)
        if prevcnt > 0
            let b:auf_highlight_lines_hlids =
                \ auf#util#clearHighlightsInRange(a:synmatch, b:auf_highlight_lines_hlids, linenr, linenr + prevcnt - 1)
        endif
        if drift != 0
            call auf#util#driftHighlightsAfterLine_nolight(b:auf_highlight_lines_hlids, linenr, drift)
        endif
        if curcnt > 0
            let b:auf_highlight_lines_hlids =
                \ auf#util#addHighlightNewLines(a:synmatch, b:auf_highlight_lines_hlids, linenr, linenr + curcnt - 1)
        endif
    endfor
endfunction

function! auf#format#InsertModeOff(synmatch) abort
    call auf#util#logVerbose('InsertModeOff: Start')
    let b:auf_linecnt_last = line('$')
    let tmpcurfile = tempname()
    try
        call writefile(getline(1, '$'), tmpcurfile)
        call s:driftHighlights(a:synmatch, b:auf_shadowpath, tmpcurfile, b:auf_difpath)
        let [b:auf_shadowpath, tmpcurfile] = [tmpcurfile, b:auf_shadowpath]
    catch /.*/
        call auf#util#echoErrorMsg('InsertModeOff: Exception: ' . v:exception)
    finally
        call delete(tmpcurfile)
    endtry
    call auf#util#highlights_On(b:auf_highlight_lines_hlids, a:synmatch)
    call auf#util#logVerbose('InsertModeOff: End')
endfunction

function! auf#format#CursorHoldInNormalMode(synmatch) abort
    call auf#util#logVerbose('CursorHoldInNormalMode: Start')
    if !exists('b:auf_linecnt_last') || b:auf_linecnt_last == line('$')
        return
    endif
    call auf#util#clearAllHighlights(b:auf_highlight_lines_hlids)
    call auf#format#InsertModeOff(a:synmatch)
    call auf#util#logVerbose('CursorHoldInNormalMode: End')
endfunction

" Functions for iterating through list of available formatters
function! auf#format#NextFormatter()
    call auf#format#find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    let b:current_formatter_index = (b:current_formatter_index + 1) % len(b:formatters)
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! auf#format#PreviousFormatter()
    call auf#format#find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    let l = len(b:formatters)
    let b:current_formatter_index = (b:current_formatter_index - 1 + l) % l
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! auf#format#CurrentFormatter()
    call auf#format#find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
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
