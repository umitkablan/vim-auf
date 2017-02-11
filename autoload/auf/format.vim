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
    let compoundtype = substitute(ftype, "[.]", "_", "g")
    if ftype =~? "[.]"
        " Try all super filetypes in search for formatters in a sane order
        let ftypes = [compoundtype] + split(ftype, "[.]")
    else
        let ftypes = [compoundtype]
    endif

    " Detect configuration for all possible ftypes
    let b:formatters = []
    for supertype in ftypes
        let formatters_var = "b:aufformatters_" . supertype
        if !exists(formatters_var)
            let formatters_var = "g:aufformatters_" . supertype
        endif
        if !exists(formatters_var)
            call auf#util#echoErrorMsg("Auf: No formatters defined for SuperType:" . supertype)
        else
            let formatters = eval(formatters_var)
            if type(formatters) != type([])
                call auf#util#echoErrorMsg("Auf: " . formatters_var . " is not a list")
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
    if !exists("b:formatprg")
        let [fmt_var, fmt_prg] = auf#util#getFormatterAtIndex(auf#format#index)
        if fmt_prg == ""
            call auf#util#echoErrorMsg("No format definition found in '" . fmt_var . "'")
            return ""
        endif
        let b:formatprg = fmt_prg
    endif
    return b:formatprg
endfunction

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! auf#format#TryAllFormatters(bang, ...) range
    " Make sure formatters are defined and detected
    if !call('auf#format#find_formatters', a:000)
        call auf#util#logVerbose("TryAllFormatters: No format definitions are defined for this FileType")
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
    let auf#format#index = b:current_formatter_index

    if !has("eval")
        call auf#util#echoErrorMsg("AutoFormat ERROR: vim has no support for eval (check :version output for +eval) - REQUIRED!")
        return 1
    endif

    let overwrite = a:bang

    let synmatch = "AufErrLine"

    while 1
        let [auffmt_var, formatprg] = auf#util#getFormatterAtIndex(auf#format#index)
        if formatprg == ""
            call auf#util#echoErrorMsg("No format definition found in '" . auffmt_var . "'")
            return 0
        endif
        let b:formatprg = formatprg

        call auf#util#logVerbose("TryAllFormatters: Trying definition in '" . auffmt_var)
        if auf#format#TryFormatter(a:firstline, a:lastline, b:formatprg, overwrite, synmatch)
            call auf#util#logVerbose("TryAllFormatters: Definition in '" . auffmt_var . "' was successful.")
            return 1
        else
            call auf#util#logVerbose("TryAllFormatters: Definition in '" . auffmt_var . "' was unsuccessful.")
            let auf#format#index = (auf#format#index + 1) % len(b:formatters)
        endif

        if auf#format#index == b:current_formatter_index
            call auf#util#logVerbose("TryAllFormatters: No format definitions were successful.")
            " Tried all formatters, none worked
            call auf#format#Fallback()
            return 0
        endif
    endwhile
endfunction

function! auf#format#Fallback()
    if exists('b:auf_remove_trailing_spaces') ? b:auf_remove_trailing_spaces == 1 : g:auf_remove_trailing_spaces == 1
        call auf#util#logVerbose("Fallback: Removing trailing whitespace...")
        call auf#format#RemoveTrailingSpaces()
    endif

    if exists('b:auf_retab') ? b:auf_retab == 1 : g:auf_retab == 1
        call auf#util#logVerbose("Fallback: Retabbing...")
        retab
    endif

    if exists('b:auf_autoindent') ? b:auf_autoindent == 1 : g:auf_autoindent == 1
        call auf#util#logVerbose("Fallback: Autoindenting...")
        " Autoindent code
        exe "normal gg=G"
    endif
endfunction

function! auf#format#formatSource(line1, line2, formatprg, inpath, outpath) abort
    let [isoutf, cmd, isranged] = auf#util#parseFormatPrg(a:formatprg, a:inpath, a:outpath, a:line1, a:line2)
    call auf#util#logVerbose("formatSource: isOutF:" . isoutf . " Command:" . cmd . " isRanged:" . isranged)
    if !isoutf
        let out = auf#util#execWithStdout(cmd)
        call writefile(split(out, '\n'), a:outpath)
    else
        let out = auf#util#execWithStderr(cmd)
    endif
    return [v:shell_error == 0, isranged, v:shell_error]
endfunction

function! auf#format#evaluateFormattedToOrig(line1, line2, formatprg, curfile, formattedf, difpath, synmatch, overwrite)
    call auf#util#clearHighlights(a:synmatch)
    call writefile(getline(1, '$'), a:curfile)
    let [res, isranged, sherr] = auf#format#formatSource(a:line1, a:line2, a:formatprg, a:curfile, a:formattedf)
    call auf#util#logVerbose("evaluateFormattedToOrig: sourceFormetted shErr:" . sherr)
    if !res
        return [2, sherr]
    endif

    let isfull = auf#util#isFullSelected(a:line1, a:line2)
    call auf#util#logVerbose("evaluateFormattedToOrig: isFull:" . isfull)
    let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, a:curfile, a:formattedf, a:difpath)
    if issame && isfull
        return [0, 0]
    elseif err
        return [3, sherr]
    endif

    if a:overwrite && isfull
        call auf#util#rewriteCurBuffer(a:formattedf)
        return [1, 0]
    endif

    if a:overwrite
        if isranged " formatter supports range
            call auf#util#logVerbose("evaluateFormattedToOrig: *formatter supports range - format fully")
            call auf#util#rewriteCurBuffer(a:formattedf)
            call writefile(getline(1, '$'), a:formattedf)
            let [res, isranged, sherr] = auf#format#formatSource(1, line('$'), a:formatprg, a:formattedf, a:curfile)
            if !res
                call auf#util#logVerbose("evaluateFormattedToOrig: error " . sherr . " trying to full-format range-formatted file.")
                return [2, sherr]
            endif
            let dif_curfile = a:formattedf
            let dif_formatf = a:curfile
        else        " formatter has only full-file support
            call auf#util#logVerbose("evaluateFormattedToOrig: *formatter doesn't support range - apply hunk")
            let [res, sherr] = auf#diff#applyHunkInPatch(g:auf_filterdiffcmd, g:auf_patchcmd, a:curfile, a:difpath, a:line1, a:line2)
            call auf#util#logVerbose("evaluateFormattedToOrig: applyHunk res:" . res . " ShErr:" . sherr)
            let dif_curfile = a:curfile
            let dif_formatf  = a:formattedf
            call auf#util#rewriteCurBuffer(dif_curfile)
        endif
        let [issame, err, sherr] = auf#diff#diffFiles(g:auf_diffcmd, dif_curfile, dif_formatf, a:difpath)
        if err
            call auf#util#logVerbose("evaluateFormattedToOrig: error " . sherr . " trying to diff files at overwrite.")
            return [3, sherr]
        endif
    else
    endif

    call auf#util#highlightLines(auf#diff#parseChangedLines(a:difpath), a:synmatch)
    return [1, 0]
endfunction

function! auf#format#TryFormatter(line1, line2, formatprg, overwrite, synmatch)
    let verb = auf#util#get_verbose()
    call auf#util#logVerbose("TryFormatter: " . a:line1 . "," . a:line2 . " " . a:formatprg . " ow:" . a:overwrite . " SynMatch:" . a:synmatch)
    if verb
        let tmpf0path = expand("%:.") . ".aftmp"
        let tmpf1path = tmpf0path . ".txt"
        call auf#util#logVerbose("TryFormatter: origTmp:" . tmpf0path . " formTmp:" . tmpf1path)
    else
        let tmpf0path = tempname()
        let tmpf1path = tempname()
    endif

    if !exists('b:auf_difpath')
        let b:auf_difpath = tempname()
    endif

    let [res, sherr] = auf#format#evaluateFormattedToOrig(a:line1, a:line2, a:formatprg, tmpf0path, tmpf1path, b:auf_difpath, a:synmatch, a:overwrite)
    call auf#util#logVerbose("TryFormatter: res:" . res . " ShErr:" . sherr)
    if res == 0 "No diff found
        call auf#util#echoSuccessMsg("AutoFormat> Format PASSED!")
    elseif res == 2 "Format program error
        call auf#util#echoErrorMsg("AutoFormat> Formatter " . b:formatters[auf#format#index] . " failed(" . sherr . ")")
    elseif res == 3 "Diff program error
        call auf#util#echoErrorMsg("AutoFormat> diff failed(" . sherr . "): " . g:auf_diffcmd)
    endif

    call auf#util#logVerbose("TryFormatter: " . tmpf0path . " and " . tmpf1path)
    call auf#util#logVerbose("TryFormatter: wasn't DELETED for analyse PLEASE MANUALLY DELETE!")
    if !verb
        call delete(tmpf0path)
        call delete(tmpf1path)
    endif
    return res < 2
endfunction

function! auf#format#justInTimeFormat(synmatch) abort
    call auf#util#get_verbose()
    if !exists("b:formatprg")
        call auf#format#find_formatters()
    endif
    if !exists("b:formatprg")
        call auf#util#logVerbose("justInTimeFormat: formatter program could not be found")
        return 1
    endif
    if !exists('b:auf_difpath')
        let b:auf_difpath = tempname()
    endif

    let tmpcurfile = tempname()
    let overwrite = 1

    call auf#util#logVerbose("justInTimeFormat: trying..")
    try
        call writefile(getline(1, '$'), tmpcurfile)
        let hunks = auf#diff#findAddedLines(g:auf_diffcmd, tmpcurfile, expand('%:.'), b:auf_difpath)
        " call autoformat#highlightLinesForJIT(hunks, a:synmatch)
        let linenr_diff = 0
        for ln in hunks
            if ln[0] < 1 || ln[1] < 1
                echoerr "justInTimeFormat: invalid hunk-lines:" . ln[0] . "-" . ln[1]
                continue
            endif
            let [ln0, ln1] = [ln[0] + linenr_diff, ln[1] + linenr_diff]
            let linecnt_prev = line('$')
            call auf#util#logVerbose("justInTimeFormat: hunk-lines:" . ln0 . "-" . ln1)
            " calculate how much we drifted from initials accumulatively
            let linenr_diff = line('$') - linecnt_prev + linenr_diff
            let res = auf#format#TryFormatter(ln0, ln1, b:formatprg, overwrite, "AufErrLine")
            call auf#util#logVerbose("justInTimeFormat: result:" . res . " drift:" . linenr_diff)
        endfor
    finally
        call auf#util#logVerbose("justInTimeFormat: deleting temporary-current-buffer")
        call delete(tmpcurfile)
    endtry
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
    let l:difpath = getbufvar(l:nr, "auf_difpath")
    if l:difpath != ""
        call delete(l:difpath)
    endif
    call setbufvar(l:nr, "auf_difpath", "")
endfunction

function! auf#format#ShowDiff() abort
    if exists("b:auf_difpath")
        exec "sp " . b:auf_difpath
        setl buftype=nofile ft=diff bufhidden=wipe ro nobuflisted noswapfile nowrap
    endif
endfunction

augroup AUF_BufDel
    autocmd!
    autocmd BufDelete * call auf#format#BufDeleted(expand('<abuf>'))
augroup END
