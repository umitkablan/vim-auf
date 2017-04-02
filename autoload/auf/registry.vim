if exists('g:loaded_auf_registry_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_registry_autoload = 1
let s:auf_registry = []

function! auf#registry#LoadAllFormatters() abort
    call auf#util#logVerbose('LoadAllFormatters: START')
    execute 'runtime! autoload/auf/formatters/*.vim'
    call auf#util#logVerbose('LoadAllFormatters: END')
endfunction

function! auf#registry#HasFormatter(ID) abort
    let ret = 0
    for rg in s:auf_registry
        if rg['ID'] ==# a:ID
            let ret = 1
            break
        endif
    endfor
    return ret
endfunction

function! auf#registry#RegisterFormatter(formatterdef) abort
    call auf#util#logVerbose('RegisterFormatter: ' . a:formatterdef['ID'] . ' ' . a:formatterdef['executable'])
    if auf#registry#HasFormatter(a:formatterdef['ID'])
        call auf#util#echoErrorMsg('RegisterFormatter: Double registry for ID:' . a:formatterdef['ID'])
        return
    endif
    let s:auf_registry += [a:formatterdef]
endfunction

function! auf#registry#FormattersCount(ftype) abort
    let [ret, i] = [0, 0]
    while i < len(s:auf_registry)
        if index(s:auf_registry[i]['filetypes'], a:ftype) > -1
            let ret += 1
        endif
        let i += 1
    endwhile
    return ret
endfunction

function! auf#registry#GetFormatterByIndex(ftype, idx) abort
    call auf#util#logVerbose('GetFormatterByIndex: ' . a:idx)
    let [ret, i] = [{}, 0]
    for rg in s:auf_registry
        if index(rg['filetypes'], a:ftype) > -1
            if i == a:idx
                let ret = rg
                let ret['needed_ftype'] = a:ftype
                break
            endif
            let i += 1
        endif
    endfor
    call auf#util#logVerbose('GetFormatterByIndex: ' . get(ret, 'ID', '__NONE__'))
    return ret
endfunction

function! auf#registry#GetFormatterByID(id, ftype) abort
    call auf#util#logVerbose('GetFormatterByID: ' . a:id)
    let ret = {}
    for rg in s:auf_registry
        if rg['ID'] ==# a:id
            if index(rg['filetypes'], a:ftype) > -1
                let ret = rg
                let ret['needed_ftype'] = a:ftype
            endif
            break
        endif
    endfor
    call auf#util#logVerbose('GetFormatterByID: ' . get(ret, 'ID', '__NONE__'))
    return ret
endfunction

function! auf#registry#BuildCmdBaseFromDef(fmtdef) abort
    return auf#formatters#{a:fmtdef['ID']}#cmdArgs(a:fmtdef['needed_ftype'])
endfunction

function! auf#registry#BuildCmdFullFromDef(fmtdef, cmdbase, outpath, line0, line1) abort
    let [isfileout, isranged, ret] = [0, 0, a:cmdbase]
    let [func_range, func_outf] = ['auf#formatters#'.a:fmtdef['ID'].'#cmdAddRange',
                                \ 'auf#formatters#'.a:fmtdef['ID'].'#cmdAddOutFile']
    if exists('*'.func_range)
        let isranged = 1
        let ret = call(func_range, [ret, a:line0, a:line1])
    endif
    if exists('*'.func_outf)
        let isfileout = 1
        let ret = call(func_outf, [ret, a:outpath])
    endif
    return [isfileout, a:fmtdef['executable'].' '.ret, isranged]
endfunction
