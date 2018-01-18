if exists('g:loaded_auf_highlights_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_highlights_autoload = 1

function! auf#highlights#relight(synmatch_chg, lnregexp_chg, synmatch_err, oldf,
                                                        \ newf, difpath) abort
    call auf#util#cleanAllHLIDs(w:, 'auf_highlight_lines_hlids')
    call auf#util#cleanAllHLIDs(w:, 'auf_newadded_lines_hlids')
    for i in b:auf_err_lnnr_list
        let w:auf_highlight_lines_hlids += [[i,0]]
    endfor
    call s:driftHighlights_FileEdited(a:synmatch_chg, a:lnregexp_chg, a:synmatch_err,
                                                \ a:oldf, a:newf, a:difpath)
    call auf#util#highlights_On(w:auf_highlight_lines_hlids, a:synmatch_err)
endfunction

function! s:driftHighlights_FileEdited(synmatch_chg, lnregexp_chg, synmatch_err,
                                                  \ oldf, newf, difpath) abort
    if !filereadable(a:oldf)
        return 0
    endif
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:oldf,
                                                        \ a:newf, a:difpath)
        if issame
        call auf#util#logVerbose('s:driftHighlights_FileEdited: no edit has detected - no diff')
        return 0
    elseif err
        call auf#util#echoErrorMsg('s:driftHighlights_FileEdited: diff error ' . err . '/'. sherr)
        return 2
    endif
    call auf#util#logVerbose_fileContent('s:driftHighlights_FileEdited: diff done:'
                \ . a:difpath, a:difpath, 's:driftHighlights_FileEdited: ========')
    let b:auf__highlight__ = 1
    let prevdrifts_tot = 0
    for [linenr, addlines, rmlines] in auf#diff#parseHunks(a:difpath)
        call auf#util#logVerbose('s:driftHighlights_FileEdited: ln:' . linenr
                            \ . ' +:' . len(addlines) . ' -:' . len(rmlines))
        let [prevcnt, curcnt] = [len(rmlines), len(addlines)]
        if prevcnt == 0 && curcnt == 0
            call auf#util#echoErrorMsg('s:driftHighlights_FileEdited: invalid hunk-lines:'
                                    \ . linenr . '-' . prevcnt . ',' . curcnt)
            continue
        endif
        let drift = curcnt - prevcnt
        call auf#util#logVerbose('s:driftHighlights_FileEdited: line:' . linenr . ' cur:'
                    \ . curcnt . ' prevcnt:' . prevcnt . ' drift:' . drift)
        if prevcnt > 0
            let w:auf_highlight_lines_hlids = auf#util#clearHighlightsInRange(
                                \ a:synmatch_err, w:auf_highlight_lines_hlids,
                                \ linenr, linenr + prevcnt - 1)
        endif
        if drift != 0
            call auf#util#driftHighlightsAfterLine(w:auf_highlight_lines_hlids,
                                                    \ linenr, drift, '', '')
        endif
        if curcnt > 0
            let linenr += prevdrifts_tot
            let w:auf_newadded_lines_hlids = auf#util#addHighlightNewLines(
                            \ w:auf_newadded_lines_hlids, linenr, linenr+curcnt-1,
                            \ a:synmatch_chg, a:lnregexp_chg)
        endif
        let prevdrifts_tot += drift
    endfor
endfunction

