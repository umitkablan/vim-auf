if exists('g:loaded_auf_formatters_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_formatters_autoload = 1

function! auf#formatters#setCurrent(fmtdef, idx, confpath) abort
    let [b:auffmt_definition, b:auffmt_current_idx] = [a:fmtdef, a:idx]
    let cpath = a:confpath
    if !len(cpath)
        let cpath = auf#util#CheckProbeFileUpRecursive(expand('%:p:h'),
                                            \ get(a:fmtdef, 'probefiles', []))
    endif
    if !len(cpath)
        let confvar = 'auffmt_' . a:fmtdef['ID'] . '_config'
        let cpath = get(g:, confvar, '')
    endif
    let b:auf__formatprg_base = auf#registry#BuildCmdBaseFromDef(a:fmtdef, cpath)
endfunction

function! auf#formatters#getCurrent() abort
    let [def, is_set] = [get(b:, 'auffmt_definition', {}), 0]
    if !empty(def) && exists('b:auffmt_current_idx')
        return [def, is_set]
    endif

    let is_set = 1
    if g:auf_probe_formatter
        let [i, def, confpath] = s:probeFormatter()
        if !empty(def)
            call auf#util#logVerbose('GetCurrentFormatter: Probed ' . def['ID']
                                                    \ . ' formatter at ' . i)
            call auf#formatters#setCurrent(def, i, confpath)
            return [def, is_set]
        endif
    endif

    let varname = 'aufformatters_' . &ft
    let fmt_list = get(g:, varname, '')
    if type(fmt_list) == type('')
        let def = auf#registry#GetFormatterByIndex(&ft, 0)
        if empty(def)
            return [def, 0]
        endif
        call auf#formatters#setCurrent(def, 0, '')
    elseif type(fmt_list) == type([])
        for i in range(0, len(fmt_list)-1)
            let id = fmt_list[i]
            call auf#util#logVerbose('GetCurrentFormatter: '
                                \ . 'Checking format definitions for ID:' . id)
            let def = auf#registry#GetFormatterByID(id, &ft)
            if !empty(def)
                call auf#formatters#setCurrent(def, i, '')
                break
            endif
        endfor
    else
        call auf#util#echoErrorMsg('Supply a list in variable: g:' . varname)
    endif
    return [def, is_set]
endfunction

function! auf#formatters#printAll() abort
    let [i, formatters] = [0, '']
    while 1
        let def = auf#registry#GetFormatterByIndex(&ft, i)
        if empty(def)
            break
        endif
        if index(def['filetypes'], &ft) > -1
            let formatters .= get(def, 'ID', '') . ', '
        endif
        let i += 1
    endwhile
    call auf#util#echoSuccessMsg('Formatters: [' . formatters[:-3] . ']')
endfunction

" Functions for iterating through list of available formatters
function! auf#formatters#setPrintNext() abort
    let [def, is_set] = auf#formatters#getCurrent()
    if is_set
        if empty(def)
            call auf#util#echoErrorMsg('No formatter could be found for:' . &ft)
            return
        endif
        call auf#util#echoSuccessMsg('Selected formatter: #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif

    let n = auf#registry#FormattersCount(&ft)
    if n < 2
        call auf#util#echoSuccessMsg('++Selected formatter (same): #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif
    let idx = (b:auffmt_current_idx + 1) % n
    let def = auf#registry#GetFormatterByIndex(&ft, idx)
    if empty(def)
        call auf#util#echoErrorMsg('Cannot select next')
        return
    endif
    call auf#formatters#setCurrent(def, idx, '')
    call auf#util#echoSuccessMsg('++Selected formatter: #'
                \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
endfunction

function! auf#formatters#setPrintPrev() abort
    let [def, is_set] = auf#formatters#getCurrent()
    if is_set
        if empty(def)
            call auf#util#echoErrorMsg('No formatter could be found for:' . &ft)
            return
        endif
        call auf#util#echoSuccessMsg('Selected formatter: #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif

    let n = auf#registry#FormattersCount(&ft)
    if n < 2
        call auf#util#echoSuccessMsg('--Selected formatter (same): #'
                    \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
        return
    endif
    let idx = b:auffmt_current_idx - 1
    if idx < 0
        let idx = n - 1
    endif
    let def = auf#registry#GetFormatterByIndex(&ft, idx)
    if empty(def)
        call auf#util#echoErrorMsg('Cannot select previous')
        return
    endif
    call auf#formatters#setCurrent(def, idx, '')
    call auf#util#echoSuccessMsg('--Selected formatter: #'
                \ . b:auffmt_current_idx . ': ' . b:auffmt_definition['ID'])
endfunction

function! auf#formatters#setPrintCurr() abort
    let [def, is_set] = auf#formatters#getCurrent()
    if empty(def)
        call auf#util#echoErrorMsg('No formatter could be found for:' . &ft)
        if is_set
        endif
        return
    endif
    call auf#util#echoSuccessMsg('Current formatter: #' . b:auffmt_current_idx
                                                        \ . ': ' . def['ID'])
    call auf#formatters#setCurrent(def, b:auffmt_current_idx, '')
endfunction

function! s:probeFormatter() abort
    call auf#util#logVerbose('s:probeFormatter: Started')
    let varname = 'aufformatters_' . &ft
    let [fmt_list, def, i, probefile] = [get(g:, varname, ''), {}, 0, '']
    if type(fmt_list) == type('')
        call auf#util#logVerbose('s:probeFormatter: '
                            \ . 'Check probe files of all defined formatters')
        while 1
            let def = auf#registry#GetFormatterByIndex(&ft, i)
            if empty(def)
                break
            endif
            let probefile = auf#util#CheckProbeFileUpRecursive(expand('%:p:h'),
                                                \ get(def, 'probefiles', []))
            if len(probefile)
                break
            endif
            let [i, def] = [i+1, {}]
        endwhile
    else
        for i in range(0, len(fmt_list)-1)
            let id = fmt_list[i]
            call auf#util#logVerbose('s:probeFormatter: '
                                \ . 'Cheking format definitions for ID:' . id)
            let def = auf#registry#GetFormatterByID(id, &ft)
            if empty(def)
                continue
            endif
            let probefile = auf#util#CheckProbeFileUpRecursive(expand('%:p:h'),
                                                \ get(def, 'probefiles', []))
            if len(probefile)
                break
            endif
            let def = {}
        endfor
    endif
    call auf#util#logVerbose('s:probeFormatter: Ended: i:' . i . ' def:'
                                                \ . get(def, 'ID', '_VOID_'))
    return [empty(def) ? -1 : i, def, probefile]
endfunction

