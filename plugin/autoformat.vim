" Function for finding the formatters for this filetype
" Result is stored in b:formatters

if !exists('g:autoformat_autoindent')
    let g:autoformat_autoindent = 1
endif

let g:autoformat_diffcmd .= " -u "
let s:verbose = &verbose || g:autoformat_verbosemode == 1

function! s:logVerbose(line) abort
    if s:verbose
        echomsg a:line
    endif
endfunction

function! s:find_formatters(...)
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
        echohl WarningMsg |
          \ echomsg "WARNING: the options g:formatprg_<filetype>, g:formatprg_args_<filetype> and g:formatprg_args_expr_<filetype> are no longer supported as of June 2015, due to major backward-incompatible improvements. Please check the README for help on how to configure your formatters." |
          \ echohl None
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

" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! s:TryAllFormatters(bang, ...) range
    " Make sure formatters are defined and detected
    if !call('<SID>find_formatters', a:000)
        call s:logVerbose("No format definitions are defined for this FileType.")
        call s:Fallback()
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
    let s:index = b:current_formatter_index

    if !has("eval")
        echohl WarningMsg |
            \ echomsg "AutoFormat ERROR: vim has no support for eval (check :version output for +eval) - REQUIRED!" |
            \ echohl None
        return 1
    endif

    let showdiff = !a:bang
    if showdiff
        let showdiff = g:autoformat_showdiff
        if exists("b:autoformat_showdiff")
            let showdiff = b:autoformat_showdiff
        endif
    endif

    let synmatch = g:autoformat_showdiff_synmatch
    if exists("b:autoformat_showdiff_synmatch")
        let synmatch = b:autoformat_showdiff_synmatch
    endif

    while 1
        " Formatter definition must be existent
        let formatdef_var = 'b:formatdef_'.b:formatters[s:index]
        if !exists(formatdef_var)
            let formatdef_var = 'g:formatdef_'.b:formatters[s:index]
        endif
        if !exists(formatdef_var)
            echoerr "No format definition found in '".formatdef_var."'."
            return 0
        endif

        " Eval twice, once for getting definition content,
        " once for getting the final expression
        let b:formatprg = eval(eval(formatdef_var))

        if s:TryFormatter(a:firstline, a:lastline, b:formatprg, !showdiff, synmatch)
            call s:logVerbose("Definition in '" . formatdef_var . "' was successful.")
            return 1
        else
            call s:logVerbose("Definition in '" . formatdef_var . "' was unsuccessful.")
            let s:index = (s:index + 1) % len(b:formatters)
        endif

        if s:index == b:current_formatter_index
            call s:logVerbose("No format definitions were successful.")
            " Tried all formatters, none worked
            call s:Fallback()
            return 0
        endif
    endwhile
endfunction

function! s:Fallback()
    if exists('b:autoformat_remove_trailing_spaces') ? b:autoformat_remove_trailing_spaces == 1 : g:autoformat_remove_trailing_spaces == 1
        call s:logVerbose("Removing trailing whitespace...")
        call s:RemoveTrailingSpaces()
    endif

    if exists('b:autoformat_retab') ? b:autoformat_retab == 1 : g:autoformat_retab == 1
        call s:logVerbose("Retabbing...")
        retab
    endif

    if exists('b:autoformat_autoindent') ? b:autoformat_autoindent == 1 : g:autoformat_autoindent == 1
        call s:logVerbose("Autoindenting...")
        " Autoindent code
        exe "normal gg=G"
    endif

endfunction

function! s:execWithStdout(cmd) abort
    let sr = &shellredir
    set shellredir=>%s\ 2>/dev/null
    let out = system(a:cmd)
    let &shellredir=sr
    return out
endfunction

function! s:execWithStderr(cmd) abort
    let sr = &shellredir
    set shellredir=>%s\ 1>/dev/tty
    let err = system(a:cmd)
    let &shellredir=sr
    return err
endfunction

function! s:parseChangedLines(diffpath) abort
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

function! s:parseFormatPrg(formatprg, inputf, outputf, line1, line2) abort
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

function! s:diffFiles(diffcmd, origf, modiff, difpath) abort
    let cmd = a:diffcmd . " " . a:origf . " " . a:modiff
    call s:logVerbose("diffCommand> " . cmd)
    let out = s:execWithStdout(cmd)
    if v:shell_error == 0 " files are the same
        return [1, 0, v:shell_error]
    elseif v:shell_error == 1 " files are different
    else " error occurred
        return [0, 1, v:shell_error]
    endif
    call writefile(split(out, '\n'), a:difpath)
    return [0, 0, v:shell_error]
endfunction

function! s:applyHunkInPatch(filterdifcmd, patchcmd, origf, difpath, line1, line2) abort
    let cmd = a:filterdifcmd . " -i " . a:origf . " --lines=" . a:line1 . "-" . a:line2 . " " . a:difpath
    call s:logVerbose("FilterDiff Command:" . cmd)
    let out = s:execWithStdout(cmd)
    call writefile(split(out, '\n'), a:difpath)
    let cmd = a:patchcmd . " < " . a:difpath
    call s:logVerbose("patch Command:" . cmd)
    let out = s:execWithStdout(cmd)
    return [0, v:shell_error]
endfunction

function! s:formatSource(line1, line2, formatprg, inpath, outpath) abort
    let [isoutf, cmd, isranged] = s:parseFormatPrg(a:formatprg, a:inpath, a:outpath, a:line1, a:line2)
    call s:logVerbose("formatSource: isOutF:" . isoutf . " Command:" . cmd . " isRanged:" . isranged)
    if !isoutf
        let out = s:execWithStdout(cmd)
        call writefile(split(out, '\n'), a:outpath)
    else
        let out = s:execWithStderr(cmd)
    endif
    return [v:shell_error == 0, isranged, v:shell_error]
endfunction

function! s:renameFile(source, target)
  " remove undo point caused via BufWritePre
  try
      silent undojoin
  catch
  endtry

  let oldff = &fileformat
  let origfperm = ''
  if exists("*getfperm")
    let origfperm = getfperm(a:target)
  endif

  call rename(a:source, a:target)

  if exists("*setfperm") && origfperm != ''
    call setfperm(a:target , origfperm)
  endif

  silent! edit!

  let &fileformat = oldff
  let &syntax = &syntax
endfunction

function! s:changeCurFile(newpath) abort
    let ismk = 0
    try
      mkview!
      let ismk = 1
    endtry
    let tmpundofile = tempname()
    exe 'wundo! ' . tmpundofile

    call s:renameFile(a:newpath, expand('%'))

    silent! exe 'rundo ' . tmpundofile
    call delete(tmpundofile)
    if ismk
      silent! loadview
    endif
endfunction

function! s:isFullSelected(line1, line2) abort
    return a:line1 == 1 && a:line2 == line('$')
endfunction

function! s:evaluateFormattedToOrig(line1, line2, formatprg, curfile, formattedf, difpath, synmatch, overwrite)
    exec 'syn clear ' . a:synmatch
    call writefile(getline(1, '$'), a:curfile)
    let [res, isranged, sherr] = s:formatSource(a:line1, a:line2, a:formatprg, a:curfile, a:formattedf)
    call s:logVerbose("sourceFormetted shErr:" . sherr)
    if !res
        return [2, sherr]
    endif

    let isfull = s:isFullSelected(a:line1, a:line2)
    call s:logVerbose("isFull:" . isfull)
    let [issame, err, sherr] = s:diffFiles(g:autoformat_diffcmd, a:curfile, a:formattedf, a:difpath)
    if issame && isfull
        return [0, 0]
    elseif err
        return [3, sherr]
    endif

    if a:overwrite
        if isfull
            call s:changeCurFile(a:formattedf)
            return [0, 0]
        endif
        if isranged
            call s:changeCurFile(a:formattedf)
            call writefile(getline(1, '$'), a:formattedf)
        endif
    endif

    if !isfull
        if isranged " formatter supports range
            call s:logVerbose("*formatter supports range - format fully")
            let [res, isranged, sherr] = s:formatSource(1, line('$'), a:formatprg, a:formattedf, a:curfile)
            if !res
                return [2, sherr]
            endif
            call s:logVerbose("diffFiles fully-formatted")
            let [issame, err, sherr] = s:diffFiles(g:autoformat_diffcmd, a:formattedf, a:curfile, a:difpath)
        else        " formatter has only full-file support
            call s:logVerbose("*formatter doesn't support range - apply hunk")
            let [res, sherr] = s:applyHunkInPatch(g:autoformat_filterdiffcmd, g:autoformat_patchcmd, a:curfile, a:difpath, a:line1, a:line2)
            call s:logVerbose("applyHunk res:" . res . " ShErr:" . sherr)
            let [issame, err, sherr] = s:diffFiles(g:autoformat_diffcmd, a:curfile, a:formattedf, a:difpath)
        endif
        if err
            return [3, sherr]
        endif
    endif

    if a:overwrite
        if isranged
            call s:changeCurFile(a:formattedf)
        else
            call s:changeCurFile(a:curfile)
        endif
    endif


    let hlines = s:parseChangedLines(a:difpath)
    for hl in hlines
        exec 'syn match '. a:synmatch . ' ".*\%' . hl . 'l.*" containedin=ALL'
    endfor

    return [1, 0]
endfunction

function! s:TryFormatter(line1, line2, formatprg, overwrite, synmatch)
    if s:verbose
        let tmpf0path = expand("%:.") . ".aftmp"
        let tmpf1path = tmpf0path . ".txt"
        echomsg "autoformat> origTmp:" . tmpf0path . " formTmp:" . tmpf1path
    else
        let tmpf0path = tempname()
        let tmpf1path = tempname()
    endif

    if !exists('b:autoformat_difpath')
        let b:autoformat_difpath = tempname()
    endif

    let [res, sherr] = s:evaluateFormattedToOrig(a:line1, a:line2, a:formatprg, tmpf0path, tmpf1path, b:autoformat_difpath, a:synmatch, a:overwrite)
    call s:logVerbose("autoformat > res:" . res . " ShErr:" . sherr)
    if res == 0 "No diff found
        echomsg "Format PASSED!"
        if exists('b:autoformat_difpath')
            call delete(b:autoformat_difpath)
            unlet! b:autoformat_difpath
        endif
    elseif res == 2 "Format program error
        echomsg "Formatter " . b:formatters[s:index] . " failed(" . sherr . ")"
    elseif res == 3 "Diff program error
        echomsg "diff failed(" . sherr . "): " . g:autoformat_diffcmd
    endif

    call s:logVerbose("autoformat> " . tmpf0path . " and " . tmpf1path)
    call s:logVerbose("autoformat> wasn't DELETED for analyse PLEASE MANUALLY DELETE!")
    if !s:verbose
        call delete(tmpf0path)
        call delete(tmpf1path)
    endif
    return res < 2
endfunction


" Functions for iterating through list of available formatters
function! s:NextFormatter()
    call s:find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    let b:current_formatter_index = (b:current_formatter_index + 1) % len(b:formatters)
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! s:PreviousFormatter()
    call s:find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    let l = len(b:formatters)
    let b:current_formatter_index = (b:current_formatter_index - 1 + l) % l
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! s:CurrentFormatter()
    call s:find_formatters()
    if !exists('b:current_formatter_index')
        let b:current_formatter_index = 0
    endif
    echomsg 'Selected formatter: '.b:formatters[b:current_formatter_index]
endfunction

function! s:ShowDiff() abort
    if exists("b:autoformat_difpath")
        exec "sp " . b:autoformat_difpath
        setl buftype=nofile ft=diff bufhidden=wipe ro nobuflisted noswapfile nowrap
    endif
endfunction

function! s:BufDeleted(bufnr) abort
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

" Save and recall window state to prevent vim from jumping to line 1: Beware
" that it should be done here due to <line1>,<line2> range.
command! -nargs=? -range=% -complete=filetype -bang -bar Autoformat
    \ let ww=winsaveview()|<line1>,<line2>call s:TryAllFormatters(<bang>0, <f-args>)|call winrestview(ww)

" Create commands for iterating through formatter list
command! NextFormatter call s:NextFormatter()
command! PreviousFormatter call s:PreviousFormatter()
command! CurrentFormatter call s:CurrentFormatter()

command! AutoformatShowDiff call s:ShowDiff()
augroup Autoformat
    autocmd!
    autocmd BufDelete * call s:BufDeleted(expand('<abuf>'))
augroup END
