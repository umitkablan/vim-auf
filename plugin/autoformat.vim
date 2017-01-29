" Function for finding the formatters for this filetype
" Result is stored in b:formatters

if !exists('g:autoformat_autoindent')
    let g:autoformat_autoindent = 1
endif

function! s:find_formatters(...)
    " Detect verbosity
    let verbose = &verbose || g:autoformat_verbosemode == 1

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
            " No formatters defined
            if verbose
                echoerr "No formatters defined for supertype ".supertype
            endif
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
        " No formatters defined
        if verbose
            echoerr "No formatters defined for filetype '".ftype."'."
        endif
        return 0
    endif
    return 1
endfunction


" Try all formatters, starting with the currently selected one, until one
" works. If none works, autoindent the buffer.
function! s:TryAllFormatters(...) range
    " Detect verbosity
    let verbose = &verbose || g:autoformat_verbosemode == 1

    " Make sure formatters are defined and detected
    if !call('<SID>find_formatters', a:000)
        " No formatters defined
        if verbose
            echomsg "No format definitions are defined for this filetype."
        endif
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

        " Detect if +python or +python3 is available, and call the corresponding function
        if !has("python") && !has("python3")
            echohl WarningMsg |
                \ echomsg "WARNING: vim has no support for python, but it is required to run the formatter!" |
                \ echohl None
            return 1
        endif
        if s:TryFormatter()
            if verbose
                echomsg "Definition in '".formatdef_var."' was successful."
            endif
            return 1
        else
            if verbose
                echomsg "Definition in '".formatdef_var."' was unsuccessful."
            endif
            let s:index = (s:index + 1) % len(b:formatters)
        endif

        if s:index == b:current_formatter_index
            if verbose
                echomsg "No format definitions were successful."
            endif
            " Tried all formatters, none worked
            call s:Fallback()
            return 0
        endif
    endwhile
endfunction

function! s:Fallback()
    " Detect verbosity
    let verbose = &verbose || g:autoformat_verbosemode == 1

    if exists('b:autoformat_remove_trailing_spaces') ? b:autoformat_remove_trailing_spaces == 1 : g:autoformat_remove_trailing_spaces == 1
        if verbose
            echomsg "Removing trailing whitespace..."
        endif
        call s:RemoveTrailingSpaces()
    endif

    if exists('b:autoformat_retab') ? b:autoformat_retab == 1 : g:autoformat_retab == 1
        if verbose
            echomsg "Retabbing..."
        endif
        retab
    endif

    if exists('b:autoformat_autoindent') ? b:autoformat_autoindent == 1 : g:autoformat_autoindent == 1
        if verbose
            echomsg "Autoindenting..."
        endif
        " Autoindent code
        exe "normal gg=G"
    endif

endfunction

function! s:execWithStdout(cmd) abort
    let sr = &shellredir
    set shellredir=>%s\ 2>/Users/i328658/asdd.txt
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

function! s:parseFormatPrg(formatprg, tmpf0path, tmpf1path) abort
    let cmd = a:formatprg
    if stridx(cmd, "##INPUTSRC##") != -1
        let cmd = substitute(cmd, "##INPUTSRC##", a:tmpf0path, 'g')
    endif
    let isoutf = 0
    if stridx(cmd, "##OUTPUTSRC##") != -1
        let isoutf = 1
        let cmd = substitute(cmd, "##OUTPUTSRC##", a:tmpf1path, 'g')
    endif
    return [isoutf, cmd]
endfunction

function! s:diffFiles(diffcmd, tmpf0path, tmpf1path) abort
    let cmd = a:diffcmd . " " . a:tmpf0path . " " . a:tmpf1path
    " if verbose
    "     echomsg("autoformat diff> " . cmd)
    " endif
    let out = s:execWithStdout(cmd)
    if v:shell_error == 0 " files are the same
        echomsg("Format PASSED!")
        call delete(a:tmpf0path)
        call delete(a:tmpf1path)
        if exists('b:autoformat_difpath')
            call delete(b:autoformat_difpath)
            unlet! b:autoformat_difpath
        endif
        return [1, 0]
    elseif v:shell_error == 1 " files are different
    else " error occurred
        echoerr("diff command failed(" . v:shell_error . "): " . a:diffcmd)
        call delete(a:tmpf0path)
        call delete(a:tmpf1path)
        return [0, 1]
    endif

    if !exists('b:autoformat_difpath')
        let b:autoformat_difpath = tempname()
    endif
    call writefile(split(out, '\n'), b:autoformat_difpath)
    return [0, 0]
endfunction

function! s:formatSrc(cmd, isoutf, tmpf0path, tmpf1path) abort
    call writefile(getline(1, '$'), a:tmpf0path)
    if !a:isoutf
        let out = s:execWithStdout(a:cmd)
        if v:shell_error
            echomsg("Formatter " . b:formatters[s:index] . " failed(" . v:shell_error . ")")
        endif
        call writefile(split(out, '\n'), a:tmpf1path)
    else
        let out = s:execWithStderr(a:cmd)
        if v:shell_error
            echomsg("Formatter " . b:formatters[s:index] . " failed(" . v:shell_error . "): " . out)
        endif
    endif
    if v:shell_error
        call delete(a:tmpf0path)
        call delete(a:tmpf1path)
        return 0
    endif
    return 1
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

function! s:changeCurFile(tmpf1path) abort
    let l:curw = {}
    try
      mkview!
    catch
      let l:curw = winsaveview()
    endtry
    let tmpundofile = tempname()
    exe 'wundo! ' . tmpundofile

    call s:renameFile(a:tmpf1path, expand('%'))

    silent! exe 'rundo ' . tmpundofile
    call delete(tmpundofile)
    if empty(l:curw)
      silent! loadview
    else
      call winrestview(l:curw)
    endif
endfunction

function! s:TryFormatter()
    let verbose = &verbose || g:autoformat_verbosemode == 1
    if exists("g:formatterpath") && g:formatterpath != ""
        let $PATH = $PATH . ":" . g:formatterpath
    endif

    if exists("b:autoformat_showdiff")
        let showdiff = b:autoformat_showdiff
    else
        let showdiff = g:autoformat_showdiff
    endif
    let diffcmd = g:autoformat_diffcmd
    let synmatch = g:autoformat_showdiff_synmatch
    if showdiff
        if exists("b:autoformat_diffcmd")
            let diffcmd = b:autoformat_diffcmd
        endif
        if exists("b:autoformat_showdiff_synmatch")
            let synmatch = b:autoformat_showdiff_synmatch
        endif
    endif
    exec 'syn clear ' . synmatch
    let diffcmd .= " -u "

    if verbose
        echomsg("autoformat> " . b:formatprg)
    endif

    let tmpf0path = expand("%:.") . ".aftmp" "tempname()
    let tmpf1path = tempname()
    let [isoutf, cmd] = s:parseFormatPrg(b:formatprg, tmpf0path, tmpf1path)
    if verbose
        echomsg("autoformat cmd> " . cmd)
    endif
    if !s:formatSrc(cmd, isoutf, tmpf0path, tmpf1path)
        return 0
    endif

    if showdiff
        let [issame, err] = s:diffFiles(diffcmd, tmpf0path, tmpf1path)
        if issame
            return 1
        elseif err
            return 0
        endif
        let hlines = s:parseChangedLines(b:autoformat_difpath)
        for hl in hlines
            exec 'syn match '. synmatch . ' ".*\%' . hl . 'l.*" containedin=ALL'
        endfor
    else
        call s:changeCurFile(tmpf1path)
    endif
    call delete(tmpf0path)
    call delete(tmpf1path)
    return 1
endfunction


" Create a command for formatting the entire buffer
" Save and recall window state to prevent vim from jumping to line 1
command! -nargs=? -range=% -complete=filetype -bar Autoformat <line1>,<line2>call s:TryAllFormatters(<f-args>)


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

" Create commands for iterating through formatter list
command! NextFormatter call s:NextFormatter()
command! PreviousFormatter call s:PreviousFormatter()
command! CurrentFormatter call s:CurrentFormatter()

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

command! AutoformatShowDiff call s:ShowDiff()
augroup Autoformat
    autocmd!
    autocmd BufDelete * call s:BufDeleted(expand('<abuf>'))
augroup END
