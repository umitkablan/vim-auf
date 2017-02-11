if exists('g:loaded_auf_util_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_util_autoload = 1

function! auf#util#get_verbose() abort
    return &verbose || g:auf_verbosemode == 1
endfunction

function! auf#util#logVerbose(line) abort
    if auf#util#get_verbose()
        echomsg a:line
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
    set shellredir=>%s\ 2>/dev/null
    let out = system(a:cmd)
    let &shellredir=sr
    return out
endfunction

function! auf#util#execWithStderr(cmd) abort
    let sr = &shellredir
    set shellredir=>%s\ 1>/dev/tty
    let err = system(a:cmd)
    let &shellredir=sr
    return err
endfunction

function! auf#util#parseFormatPrg(formatprg, inputf, outputf, line1, line2) abort
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

function! auf#util#getFormatterAtIndex(index) abort
    " Formatter definition must be existent
    let auffmt_var = 'b:auffmt_' . b:formatters[a:index]
    if !exists(auffmt_var)
        let auffmt_var = 'g:auffmt_' . b:formatters[a:index]
    endif
    if !exists(auffmt_var)
        return [auffmt_var, ""]
    endif
    " Eval twice, once for getting definition content,
    " once for getting the final expression
    return [auffmt_var, eval(eval(auffmt_var))]
endfunction

function! auf#util#rewriteCurBuffer(newpath) abort
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

function! auf#util#clearHighlights(synmatch) abort
    execute 'syn clear ' . a:synmatch
endfunction

function! auf#util#highlightLines(hlines, synmatch) abort
    for hl in a:hlines
        exec 'syn match '. a:synmatch . ' ".*\%' . hl . 'l.*" containedin=ALL'
    endfor
endfunction

function! auf#util#highlightLinesForJIT(hunks, synmatch) abort
    for hunk in a:hunks
        let ln = hunk[0]
        while ln <= hunk[1]
            exec 'syn match '. a:synmatch . ' ".*\%' . ln . 'l.*" containedin=ALL'
            let ln += 1
        endwhile
    endfor
endfunction
