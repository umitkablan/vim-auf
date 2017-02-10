
function! autoformat#logVerbose(line) abort
    if s:verbose
        echomsg a:line
    endif
endfunction

function! autoformat#echoSuccessMsg(line) abort
    echohl DiffAdd | echomsg a:line | echohl None
endfunction

function! autoformat#echoErrorMsg(line) abort
    echohl ErrorMsg | echomsg a:line | echohl None
endfunction

" Function for finding the formatters for this filetype
" Result is stored in b:formatters
function! autoformat#find_formatters(...)
    " Extract filetype to be used
    let ftype = a:0 ? a:1 : &filetype
    " Support composite filetypes by replacing dots with underscores
    let compoundtype = substitute(ftype, "[.]", "_", "g")
    if ftype =~? "[.]"
        " Try all super filetypes in search for formatters in a sane order
        let ftypes = [compoundtype] + split(ftype, "[.]")
    else
        let ftypes = [compoundtype]
    endif

    " Warn for backward incompatible configuration
    let old_formatprg_var = "g:formatprg_".compoundtype
    let old_formatprg_args_var = "g:formatprg_args_".compoundtype
    let old_formatprg_args_expr_var = "g:formatprg_args_expr_".compoundtype
    if exists(old_formatprg_var) || exists(old_formatprg_args_var) || exists(old_formatprg_args_expr_var)
        call autoformat#echoErrorMsg("WARNING: the options g:formatprg_<filetype>, g:formatprg_args_<filetype> and g:formatprg_args_expr_<filetype> are no longer supported as of June 2015, due to major backward-incompatible improvements. Please check the README for help on how to configure your formatters.")
    endif

    " Detect configuration for all possible ftypes
    let b:formatters = []
    for supertype in ftypes
        let formatters_var = "b:formatters_".supertype
        if !exists(formatters_var)
            let formatters_var = "g:formatters_".supertype
        endif
        if !exists(formatters_var)
            echoerr "No formatters defined for SuperType:" . supertype
        else
            let formatters = eval(formatters_var)
            if type(formatters) != type([])
                echoerr formatters_var." is not a list"
            else
                let b:formatters = b:formatters + formatters
            endif
        endif
    endfor

    if len(b:formatters) == 0
        echoerr "No formatters defined for FileType:'" . ftype . "'."
        return 0
    endif
    return 1
endfunction

function! autoformat#getFormatPrgWithIndex(index) abort
    " Formatter definition must be existent
    let formatdef_var = 'b:formatdef_'.b:formatters[a:index]
    if !exists(formatdef_var)
        let formatdef_var = 'g:formatdef_'.b:formatters[a:index]
    endif
    if !exists(formatdef_var)
        return [formatdef_var, ""]
    endif

    " Eval twice, once for getting definition content,
    " once for getting the final expression
    return [formatdef_var, eval(eval(formatdef_var))]
endfunction

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! autoformat#TryAllFormatters(bang, ...) range
    let s:verbose = &verbose || g:autoformat_verbosemode == 1

    " Make sure formatters are defined and detected
    if !call('autoformat#find_formatters', a:000)
        call autoformat#logVerbose("TryAllFormatters: No format definitions are defined for this FileType.")
        call autoformat#Fallback()
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
    let autoformat#index = b:current_formatter_index

    if !has("eval")
        call autoformat#echoErrorMsg("AutoFormat ERROR: vim has no support for eval (check :version output for +eval) - REQUIRED!")
        return 1
    endif

    let overwrite = a:bang

    let synmatch = "AutoformatErrLine"

    while 1
        let [formatdef_var, formatprg] = autoformat#getFormatPrgWithIndex(autoformat#index)
        if formatprg == ""
            echoerr "No format definition found in '" . formatdef_var . "'."
            return 0
        endif
        let b:formatprg = formatprg

        call autoformat#logVerbose("TryAllFormatters: Trying definition in '" . formatdef_var)
        if autoformat#TryFormatter(a:firstline, a:lastline, b:formatprg, overwrite, synmatch)
            call autoformat#logVerbose("TryAllFormatters: Definition in '" . formatdef_var . "' was successful.")
            return 1
        else
            call autoformat#logVerbose("TryAllFormatters: Definition in '" . formatdef_var . "' was unsuccessful.")
            let autoformat#index = (autoformat#index + 1) % len(b:formatters)
        endif

        if autoformat#index == b:current_formatter_index
            call autoformat#logVerbose("TryAllFormatters: No format definitions were successful.")
            " Tried all formatters, none worked
            call autoformat#Fallback()
            return 0
        endif
    endwhile
endfunction

function! autoformat#Fallback()
    if exists('b:autoformat_remove_trailing_spaces') ? b:autoformat_remove_trailing_spaces == 1 : g:autoformat_remove_trailing_spaces == 1
        call autoformat#logVerbose("Fallback: Removing trailing whitespace...")
        call autoformat#RemoveTrailingSpaces()
    endif

    if exists('b:autoformat_retab') ? b:autoformat_retab == 1 : g:autoformat_retab == 1
        call autoformat#logVerbose("Fallback: Retabbing...")
        retab
    endif

    if exists('b:autoformat_autoindent') ? b:autoformat_autoindent == 1 : g:autoformat_autoindent == 1
        call autoformat#logVerbose("Fallback: Autoindenting...")
        " Autoindent code
        exe "normal gg=G"
    endif

endfunction

function! autoformat#execWithStdout(cmd) abort
    let sr = &shellredir
    set shellredir=>%s\ 2>/dev/null
    let out = system(a:cmd)
    let &shellredir=sr
    return out
endfunction

function! autoformat#execWithStderr(cmd) abort
    let sr = &shellredir
    set shellredir=>%s\ 1>/dev/tty
    let err = system(a:cmd)
    let &shellredir=sr
    return err
endfunction

function! autoformat#parseChangedLines(diffpath) abort
    let hlines  = []
    let lnfirst = -1
    let deletelast = 0
    let i = 0
    let flines = readfile(a:diffpath)
    for line in flines
        if line == ""
            continue
        elseif line[0] == "@"
            let lnfirst = str2nr(line[4:stridx(line, ',')])
            continue
        elseif lnfirst == -1
            continue
        endif
        if line[0] == "-"
            let hlines += [lnfirst]
        endif
        if line[0] != "+"
            let lnfirst += 1
        endif
        if line == "\\ No newline at end of file" && i == len(flines)-2 && flines[i+1] == ""
            let deletelast = 1
        endif
        let i += 1
    endfor
    if deletelast && len(hlines)
        let hlines = hlines[0:-2]
    endif
    return hlines
endfunction

function! autoformat#findAddedLines(diffcmd, curfile, oldfile, difpath) abort
    let ret = []
    let [issame, err, sherr] = autoformat#diffFiles(a:diffcmd, a:oldfile, a:curfile, a:difpath)
    if issame
        return ret
    elseif err
        call autoformat#logVerbose("findAddedLines: error " . err . "/". sherr . " diff current")
        return ret
    endif
    call autoformat#logVerbose("findAddedLines: diff done to " . a:difpath)

    let flines = readfile(a:difpath)
    let [lnfirst, ln0, ln1] = [0, 0, 0]
    for line in flines
        if line == ""
            continue
        elseif line[0] == "@"
            let plusidx = stridx(line, '+')
            let commaidx = stridx(line, ',', plusidx)
            if plusidx < 0 || commaidx < 0
                call autoformat#logVerbose("findAddedLines: !!plus/comma is not found in the diff line!!")
                let lnfirst = 0
                continue
            endif
            let lnfirst = str2nr(line[plusidx+1:commaidx])
        elseif lnfirst > 0
            if line[0] != '+' && ln0 > 0
                let ret += [[ln0, ln1]]
                let [ln0, ln1] = [0, 0]
            endif
            if line[0] == '+'
                if ln0 == 0
                    let [ln0, ln1] = [lnfirst, lnfirst]
                else
                    let ln1 += 1
                endif
            endif
            if line[0] != '-'
                let lnfirst += 1
            endif
        endif
    endfor
    if ln0 > 0
        let ret += [[ln0, ln1]]
    endif
    return ret
endfunction

function! autoformat#parseFormatPrg(formatprg, inputf, outputf, line1, line2) abort
    let cmd = a:formatprg
    if stridx(cmd, "##INPUTSRC##") != -1
        let cmd = substitute(cmd, "##INPUTSRC##", a:inputf, 'g')
    endif
    let isoutf = 0
    if stridx(cmd, "##OUTPUTSRC##") != -1
        let isoutf = 1
        let cmd = substitute(cmd, "##OUTPUTSRC##", a:outputf, 'g')
    endif
    let isranged = 0
    if stridx(cmd, "##FIRSTLINE##") != -1
        let isranged += 1
        let cmd = substitute(cmd, "##FIRSTLINE##", a:line1, 'g')
    endif
    if stridx(cmd, "##LASTLINE##") != -1
        let isranged += 1
        let cmd = substitute(cmd, "##LASTLINE##", a:line2, 'g')
    endif
    return [isoutf, cmd, isranged]
endfunction

function! autoformat#diffFiles(diffcmd, origf, modiff, difpath) abort
    let cmd = a:diffcmd . " " . a:origf . " " . a:modiff
    call autoformat#logVerbose("diffFiles: command> " . cmd)
    let out = autoformat#execWithStdout(cmd)
    if v:shell_error == 0 " files are the same
        return [1, 0, v:shell_error]
    elseif v:shell_error == 1 " files are different
    else " error occurred
        return [0, 1, v:shell_error]
    endif
    call writefile(split(out, '\n'), a:difpath)
    return [0, 0, v:shell_error]
endfunction

function! autoformat#applyHunkInPatch(filterdifcmd, patchcmd, origf, difpath, line1, line2) abort
    let cmd = a:filterdifcmd . " -i " . a:origf . " --lines=" . a:line1 . "-" . a:line2 . " " . a:difpath
    call autoformat#logVerbose("applyHunkInPatch: filter-diff Command:" . cmd)
    let out = autoformat#execWithStdout(cmd)
    call writefile(split(out, '\n'), a:difpath)
    let cmd = a:patchcmd . " < " . a:difpath
    call autoformat#logVerbose("applyHunkInPatch: patch Command:" . cmd)
    let out = autoformat#execWithStdout(cmd)
    return [0, v:shell_error]
endfunction

function! autoformat#formatSource(line1, line2, formatprg, inpath, outpath) abort
    let [isoutf, cmd, isranged] = autoformat#parseFormatPrg(a:formatprg, a:inpath, a:outpath, a:line1, a:line2)
    call autoformat#logVerbose("formatSource: isOutF:" . isoutf . " Command:" . cmd . " isRanged:" . isranged)
    if !isoutf
        let out = autoformat#execWithStdout(cmd)
        call writefile(split(out, '\n'), a:outpath)
    else
        let out = autoformat#execWithStderr(cmd)
    endif
    return [v:shell_error == 0, isranged, v:shell_error]
endfunction

function! autoformat#rewriteCurBuffer(newpath) abort
    let ismk = 0
    try
        mkview!
        let ismk = 1
    endtry
    " let pos = getpos('.')
    let [v_reg, v_type] = [getreg('v'), getregtype('v')]

    let tmpundofile = tempname()
    execute 'wundo! ' . tmpundofile
    try
        " silent keepjumps execute "1,$d|0read " . a:newpath . "|$d"
        let @v = join(readfile(a:newpath), "\n")
        silent keepjumps normal! ggVG"vp
    finally
        silent! execute 'rundo ' . tmpundofile
        call delete(tmpundofile)
        call setreg('v', v_reg, v_type)
        " call setpos('.', pos)
        if ismk
            silent! loadview
        endif
    endtry
endfunction

function! autoformat#isFullSelected(line1, line2) abort
    return a:line1 == 1 && a:line2 == line('$')
endfunction

function! autoformat#clearHighlights(synmatch) abort
    execute 'syn clear ' . a:synmatch
endfunction

function! autoformat#highlightLines(hlines, synmatch) abort
    for hl in a:hlines
        exec 'syn match '. a:synmatch . ' ".*\%' . hl . 'l.*" containedin=ALL'
    endfor
endfunction
function! autoformat#highlightLinesForJIT(hunks, synmatch) abort
    for hunk in a:hunks
        let ln = hunk[0]
        while ln <= hunk[1]
            exec 'syn match '. a:synmatch . ' ".*\%' . ln . 'l.*" containedin=ALL'
            let ln += 1
        endwhile
    endfor
endfunction
function! autoformat#animateHunksForJIT(hunks, synmatch) abort
    call autoformat#highlightLinesForJIT(a:hunks, a:synmatch)
    " sleep 250m
    " call autoformat#clearHighlights(a:synmatch)
endfunction

function! autoformat#evaluateFormattedToOrig(line1, line2, formatprg, curfile, formattedf, difpath, synmatch, overwrite)
    call autoformat#clearHighlights(a:synmatch)
    call writefile(getline(1, '$'), a:curfile)
    let [res, isranged, sherr] = autoformat#formatSource(a:line1, a:line2, a:formatprg, a:curfile, a:formattedf)
    call autoformat#logVerbose("evaluateFormattedToOrig: sourceFormetted shErr:" . sherr)
    if !res
        return [2, sherr]
    endif

    let isfull = autoformat#isFullSelected(a:line1, a:line2)
    call autoformat#logVerbose("evaluateFormattedToOrig: isFull:" . isfull)
    let [issame, err, sherr] = autoformat#diffFiles(g:autoformat_diffcmd, a:curfile, a:formattedf, a:difpath)
    if issame && isfull
        return [0, 0]
    elseif err
        return [3, sherr]
    endif

    if a:overwrite && isfull
        call autoformat#rewriteCurBuffer(a:formattedf)
        return [1, 0]
    endif

    if a:overwrite
        if isranged " formatter supports range
            call autoformat#logVerbose("evaluateFormattedToOrig: *formatter supports range - format fully")
            call autoformat#rewriteCurBuffer(a:formattedf)
            call writefile(getline(1, '$'), a:formattedf)
            let [res, isranged, sherr] = autoformat#formatSource(1, line('$'), a:formatprg, a:formattedf, a:curfile)
            if !res
                call autoformat#logVerbose("evaluateFormattedToOrig: error " . sherr . " trying to full-format range-formatted file.")
                return [2, sherr]
            endif
            let dif_curfile = a:formattedf
            let dif_formatf = a:curfile
        else        " formatter has only full-file support
            call autoformat#logVerbose("evaluateFormattedToOrig: *formatter doesn't support range - apply hunk")
            let [res, sherr] = autoformat#applyHunkInPatch(g:autoformat_filterdiffcmd, g:autoformat_patchcmd, a:curfile, a:difpath, a:line1, a:line2)
            call autoformat#logVerbose("evaluateFormattedToOrig: applyHunk res:" . res . " ShErr:" . sherr)
            let dif_curfile = a:curfile
            let dif_formatf  = a:formattedf
            call autoformat#rewriteCurBuffer(dif_curfile)
        endif
        let [issame, err, sherr] = autoformat#diffFiles(g:autoformat_diffcmd, dif_curfile, dif_formatf, a:difpath)
        if err
            call autoformat#logVerbose("evaluateFormattedToOrig: error " . sherr . " trying to diff files at overwrite.")
            return [3, sherr]
        endif
    else
    endif

    call autoformat#highlightLines(autoformat#parseChangedLines(a:difpath), a:synmatch)
    return [1, 0]
endfunction

function! autoformat#TryFormatter(line1, line2, formatprg, overwrite, synmatch)
    call autoformat#logVerbose("TryFormatter: " . a:line1 . "," . a:line2 . " " . a:formatprg . " ow:" . a:overwrite . " SynMatch:" . a:synmatch)
    if s:verbose
        let tmpf0path = expand("%:.") . ".aftmp"
        let tmpf1path = tmpf0path . ".txt"
        call autoformat#logVerbose("TryFormatter: origTmp:" . tmpf0path . " formTmp:" . tmpf1path)
    else
        let tmpf0path = tempname()
        let tmpf1path = tempname()
    endif

    if !exists('b:autoformat_difpath')
        let b:autoformat_difpath = tempname()
    endif

    let [res, sherr] = autoformat#evaluateFormattedToOrig(a:line1, a:line2, a:formatprg, tmpf0path, tmpf1path, b:autoformat_difpath, a:synmatch, a:overwrite)
    call autoformat#logVerbose("TryFormatter: res:" . res . " ShErr:" . sherr)
    if res == 0 "No diff found
        call autoformat#echoSuccessMsg("AutoFormat> Format PASSED!")
    elseif res == 2 "Format program error
        call autoformat#echoErrorMsg("AutoFormat> Formatter " . b:formatters[autoformat#index] . " failed(" . sherr . ")")
    elseif res == 3 "Diff program error
        call autoformat#echoErrorMsg("AutoFormat> diff failed(" . sherr . "): " . g:autoformat_diffcmd)
    endif

    call autoformat#logVerbose("TryFormatter: " . tmpf0path . " and " . tmpf1path)
    call autoformat#logVerbose("TryFormatter: wasn't DELETED for analyse PLEASE MANUALLY DELETE!")
    if !s:verbose
        call delete(tmpf0path)
        call delete(tmpf1path)
    endif
    return res < 2
endfunction

function! autoformat#justInTimeFormat(synmatch) abort
    let s:verbose = &verbose || g:autoformat_verbosemode == 1
    if !exists("b:formatprg")
        call autoformat#find_formatters()
    endif
    if !exists('b:autoformat_difpath')
        let b:autoformat_difpath = tempname()
    endif

    let tmpcurfile = tempname()
    let overwrite = 1

    call autoformat#logVerbose("justInTimeFormat: started")
    try
        call writefile(getline(1, '$'), tmpcurfile)
        let hunks = autoformat#findAddedLines(g:autoformat_diffcmd, tmpcurfile, expand('%:.'), b:autoformat_difpath)
        " call autoformat#highlightLinesForJIT(hunks, a:synmatch)
        let linenr_diff = 0
        for ln in hunks
            if ln[0] < 1 || ln[1] < 1
                echoerr "justInTimeFormat: invalid hunk-lines:" . ln[0] . "-" . ln[1]
                continue
            endif
            let [ln0, ln1] = [ln[0] + linenr_diff, ln[1] + linenr_diff]
            let linecnt_prev = line('$')
            call autoformat#logVerbose("justInTimeFormat: hunk-lines:" . ln0 . "-" . ln1)
            " calculate how much we drifted from initials accumulatively
            let linenr_diff = line('$') - linecnt_prev + linenr_diff
            let res = autoformat#TryFormatter(ln0, ln1, b:formatprg, overwrite, "AutoformatErrLine")
            call autoformat#logVerbose("justInTimeFormat: result:" . res . " drift:" . linenr_diff)
        endfor
    finally
        call autoformat#logVerbose("justInTimeFormat: deleting temporary-current-buffer")
        call delete(tmpcurfile)
    endtry
endfunction

" Functions for iterating through list of available formatters
function! autoformat#NextFormatter()
    call autoformat#find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    let b:current_formatter_index = (b:current_formatter_index + 1) % len(b:formatters)
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! autoformat#PreviousFormatter()
    call autoformat#find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    let l = len(b:formatters)
    let b:current_formatter_index = (b:current_formatter_index - 1 + l) % l
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! autoformat#CurrentFormatter()
    call autoformat#find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! autoformat#ShowDiff() abort
    if exists("b:autoformat_difpath")
        exec "sp " . b:autoformat_difpath
        setl buftype=nofile ft=diff bufhidden=wipe ro nobuflisted noswapfile nowrap
    endif
endfunction

function! autoformat#BufDeleted(bufnr) abort
    let l:nr = str2nr(a:bufnr)
    if bufexists(l:nr) && !buflisted(l:nr)
        return
    endif
    let l:difpath = getbufvar(l:nr, "autoformat_difpath")
    if l:difpath != ""
        call delete(l:difpath)
    endif
    call setbufvar(l:nr, "autoformat_difpath", "")
endfunction

function! AutoformatFormatRange(line1, line2) abort
    let overwrite = 1
    call autoformat#TryFormatter(a:line1, a:line2, b:formatprg, overwrite, "AutoformatErrLine")
endfunction

augroup AUF_BufDel
    autocmd!
    autocmd BufDelete * call autoformat#BufDeleted(expand('<abuf>'))
augroup END
