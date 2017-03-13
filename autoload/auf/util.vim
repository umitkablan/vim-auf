if exists('g:loaded_auf_util_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_util_autoload = 1
let s:is_win = has('win32') || has('win64')

function! auf#util#get_verbose() abort
    return &verbose || g:auf_verbosemode == 1
endfunction

function! auf#util#logVerbose(line) abort
    if auf#util#get_verbose()
        echomsg a:line
    endif
endfunction

function! auf#util#logVerbose_fileContent(pretext, filepath, posttext) abort
    if auf#util#get_verbose()
        echomsg a:pretext
        let flines = readfile(a:filepath)
        for fl in flines
            echomsg fl
        endfor
        echomsg a:posttext
    endif
endfunction

function! auf#util#echoSuccessMsg(line) abort
    echohl DiffAdd | echomsg a:line | echohl None
endfunction

function! auf#util#echoErrorMsg(line) abort
    echohl ErrorMsg | echomsg a:line | echohl None
endfunction

function! auf#util#isFullSelected(line1, line2) abort
    return a:line1 == 1 && a:line2 == line('$')
endfunction

function! auf#util#execWithStdout(cmd) abort
    let sr = &shellredir
    if !s:is_win
        set shellredir=>%s\ 2>/dev/null
    endif
    call auf#util#logVerbose('execWithStdout: CMD:' . a:cmd)
    let out = system(a:cmd)
    let &shellredir=sr
    return out
endfunction

function! auf#util#execWithStderr(cmd) abort
    let sr = &shellredir
    if !s:is_win
        set shellredir=>%s\ 1>/dev/tty
    endif
    call auf#util#logVerbose('execWithStderr: CMD:' . a:cmd)
    let err = system(a:cmd)
    let &shellredir=sr
    return err
endfunction

function! auf#util#parseFormatPrg(formatprg, inputf, outputf, line1, line2) abort
    let cmd = a:formatprg
    if stridx(cmd, '##INPUTSRC##') != -1
        let inputf = substitute(a:inputf, '\\', '\\\\', 'g')
        let cmd = substitute(cmd, '##INPUTSRC##', inputf, 'g')
    endif
    let isoutf = 0
    if stridx(cmd, '##OUTPUTSRC##') != -1
        let isoutf = 1
        let outputf = substitute(a:outputf, '\\', '\\\\', 'g')
        let cmd = substitute(cmd, '##OUTPUTSRC##', outputf, 'g')
    endif
    let isranged = 0
    if stridx(cmd, '##FIRSTLINE##') != -1
        let isranged += 1
        let cmd = substitute(cmd, '##FIRSTLINE##', a:line1, 'g')
    endif
    if stridx(cmd, '##LASTLINE##') != -1
        let isranged += 1
        let cmd = substitute(cmd, '##LASTLINE##', a:line2, 'g')
    endif
    return [isoutf, cmd, isranged]
endfunction

function! auf#util#getFormatterAtIndex(index) abort
    " Formatter definition must be existent
    let auffmt_var = 'b:auffmt_' . b:formatters[a:index]
    if !exists(auffmt_var)
        let auffmt_var = 'g:auffmt_' . b:formatters[a:index]
    endif
    if !exists(auffmt_var)
        return [auffmt_var, '']
    endif
    call auf#util#logVerbose('getFormatterAtIndex: evaluating "' . auffmt_var . '"')
    " Eval twice, once for getting definition content,
    " once for getting the final expression
    return [auffmt_var, eval(eval(auffmt_var))]
endfunction

function! auf#util#replaceLines(linenr, linecnt, lines) abort
    let execmd = '' . a:linenr . ',' . (a:linenr + a:linecnt - 1) . 'delete _'
    keepjumps silent execute execmd
    let execmd = '' . (a:linenr - 1) . 'put=a:lines'
    keepjumps silent execute execmd
endfunction

function! auf#util#addLines(linenr, lines) abort
    let execmd = '' . a:linenr . 'put=a:lines'
    keepjumps silent execute execmd
endfunction

function! auf#util#removeLines(linenr, linecnt) abort
    let execmd = '' . a:linenr . ',' . (a:linenr + a:linecnt - 1) . 'delete _'
    keepjumps silent execute execmd
endfunction

function! auf#util#rewriteCurBuffer(newpath) abort
    let pos = getpos('.')
    let linecnt0 = line('$')
    let linecnt1 = linecnt0

    let tmpundofile = tempname()
    execute 'wundo! ' . tmpundofile
    try
        "keepjumps ?
        silent execute '%delete _|0read ' . a:newpath . '|$delete _'
        let linecnt1 = line('$')
    finally
        call setpos('.', pos)
        if linecnt1 > linecnt0
            execute 'normal! ' . (linecnt1 - linecnt0) . 'j$'
        elseif linecnt1 < linecnt0
            execute 'normal! ' . (linecnt0 - linecnt1) . 'k$'
        endif
        silent! execute 'rundo ' . tmpundofile
        call delete(tmpundofile)
    endtry
endfunction

function! s:hlLine(synmatch, linenum, hl_pattern) abort
    if a:synmatch ==# '' || a:hl_pattern ==# ''
        return 0
    endif
    if exists('*matchadd')
        if a:hl_pattern ==# '$'
            "   1) match whole line (should be *fast*)
            let ret = matchaddpos(a:synmatch, [a:linenum])
        else
            "   2) match line with user defined pattern
            let linepat = substitute(a:hl_pattern, '##LINENUM##', a:linenum, 'g')
            let ret = matchadd(a:synmatch, linepat)
            "   3) match line with count characters from beginning (fast)
            " let ret = matchaddpos(a:synmatch, [[a:linenum, 1, a:count]])
        endif
    else
        let linepat = '.*\%' . a:linenum . 'l.*'
        execute '2match ' . a:synmatch . ' /' . linepat . '/'
        let ret = 2
    endif
    return ret
endfunction

function! s:hlClear(hlid) abort
    if !a:hlid
        return 0
    endif
    if exists('*matchadd')
        silent! call matchdelete(a:hlid)
    else
        2match none
    endif
    return 0
endfunction

function! auf#util#clearAllHighlights(hlids) abort
    call auf#util#logVerbose('clearAllHiglights: @' . len(a:hlids))
    " execute 'syn clear ' . a:synmatch
    let i = 0
    while i < len(a:hlids)
        let hlid = a:hlids[i][1]
        let a:hlids[i][1] = s:hlClear(hlid)
        let i += 1
    endwhile
    call auf#util#logVerbose('clearAllHiglights: DONE @' . len(a:hlids))
endfunction

function! auf#util#clearHighlightsInRange(synmatch, hlids, line1, line2) abort
    call auf#util#logVerbose('clearHighlightsInRange: ' . a:line1 . '-' . a:line2 . ' @' . len(a:hlids))
    let ret = []
    if len(a:hlids) < 1
        return ret
    endif
    if a:hlids[0][1] == 2
        call s:hlClear(2)
        for ll in a:hlids
            let hl = ll[0]
            if hl < a:line1 || hl > a:line2
                let hlid = s:hlLine(a:synmatch, hl, g:auf_highlight_pattern)
                let ret += [[hl, hlid]]
            endif
        endfor
    else
        for ll in a:hlids
            let [hl, hlid] = [ll[0], ll[1]]
            if hl < a:line1 || hl > a:line2
                let ret += [[hl, hlid]]
                continue
            endif
            call s:hlClear(hlid)
        endfor
    endif
    call auf#util#logVerbose('clearHighlightsInRange: DONE @' . len(ret))
    return ret
endfunction

function! auf#util#addHighlightNewLines(hlids, line1, line2, synmatch, lnregexp) abort
    call auf#util#logVerbose('addHighlightNewLines: ' . a:line1 . '-' . a:line2 . ' @' . len(a:hlids))
    let [ret, ln1, ln2, i] = [[], a:line1, a:line2+1, 0]
    while i < len(a:hlids)
        let hll = a:hlids[i]
        if hll[0] <= ln1
            let ret += [hll]
            let i += 1
            if hll[0] == ln1
                let ln1 += 1
            endif
        elseif ln1 < ln2
            let ret += [[ln1, s:hlLine(a:synmatch, ln1, a:lnregexp)]]
            let ln1 += 1
        else
            let ret += [hll]
            let i += 1
        endif
    endwhile
    while ln1 < ln2
        let ret += [[ln1, s:hlLine(a:synmatch, ln1, a:lnregexp)]]
        let ln1 += 1
    endwhile
    call auf#util#logVerbose('addHighlightNewLines: DONE @' . len(ret))
    return ret
endfunction

function! auf#util#driftHighlightsAfterLine(hlids, linenr, drift, synmatch, hlpattern) abort
    call auf#util#logVerbose('driftHighlightsAfterLine: line:' . a:linenr . ' drift:' . a:drift . ' @' . len(a:hlids))
    let i = 0
    while i < len(a:hlids)
        let [hline, hlid] = a:hlids[i]
        if hline >= a:linenr
            let hline += a:drift
            let hlid = s:hlClear(hlid)
            if a:synmatch
                let hlid = s:hlLine(a:synmatch, hline, a:hlpattern)
            endif
            let a:hlids[i] = [hline, hlid]
        endif
        let i += 1
    endwhile
    call auf#util#logVerbose('driftHighlightsAfterLine: DONE @' . len(a:hlids))
endfunction

function! auf#util#highlights_On(hlids, synmatch) abort
    call auf#util#logVerbose('highlights_On:' . a:synmatch . ' @' . len(a:hlids))
    if a:synmatch ==# ''
        return
    endif
    let i = 0
    while i < len(a:hlids)
        let [hline, hlid] = [a:hlids[i][0], a:hlids[i][1]]
        if !hlid
            let a:hlids[i][1] = s:hlLine(a:synmatch, hline, g:auf_highlight_pattern)
        endif
        let i += 1
    endwhile
    call auf#util#logVerbose('highlights_On: DONE @' . len(a:hlids))
endfunction

function! auf#util#highlightLines(hlines, synmatch) abort
    call auf#util#logVerbose('highlightLines:' . a:synmatch . ' @' . len(a:hlines))
    let ret = []
    for hl in a:hlines
        let hlid = s:hlLine(a:synmatch, hl, g:auf_highlight_pattern)
        let ret += [[hl, hlid]]
    endfor
    call auf#util#logVerbose('highlightLines: DONE @' . len(ret))
    return ret
endfunction

