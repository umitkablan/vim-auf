if exists('g:loaded_auf_diff_autoload') || !exists('g:loaded_auf_plugin')
    finish
endif
let g:loaded_auf_diff_autoload = 1

function! auf#diff#findHunks(diffcmd, curfile, oldfile, difpath) abort
    let [issame, err, sherr] = auf#diff#diffFiles(a:diffcmd, a:oldfile, a:curfile, a:difpath)
    if issame
        return []
    elseif err
        call auf#util#logVerbose('findAddedLines: error ' . err . '/'. sherr . ' diff current')
        return []
    endif
    call auf#util#logVerbose()
    call auf#util#logVerbose_fileContent('findHunks: diff done to ' . a:difpath, a:difpath, 'findHunks: ========')
    return auf#diff#parseChangedLines(a:difpath)
endfunction

function! auf#diff#parseHunks(difpath) abort
    let flines = readfile(a:difpath)
    let [prevnr, curnr, ret, addedlines, rmlines] = [0, 0, [], [], []]
    for line in flines
        if line ==# ''
            continue
        elseif line[0] ==# '@'
            let prevnr = str2nr(line[4:stridx(line, ',')])
            let plusidx = stridx(line, '+')
            let commaidx = stridx(line, ',', plusidx)
            if plusidx < 0 || commaidx < 0
                call auf#util#logVerbose('findHunks: !!plus/comma is not found in the diff line!!')
                let [prevnr, curnr, addedlines, rmlines] = [0, 0, [], []]
                continue
            endif
            let curnr = str2nr(line[plusidx+1:commaidx])
        elseif prevnr > 0
            if line[0] ==# '-'
                let prevnr += 1
                let rmlines += [line[1:]]
            elseif line[0] ==# '+'
                let curnr += 1
                let addedlines += [line[1:]]
            elseif line[0] ==# ' '
                if len(rmlines) > 0 || len(addedlines) > 0
                    let ret += [[(prevnr-len(rmlines)), addedlines, rmlines]]
                    let [addedlines, rmlines] = [[], []]
                endif
                let [prevnr, curnr] = [prevnr+1, curnr+1]
            endif
        endif
    endfor
    if len(rmlines) > 0 || len(addedlines) > 0
        let ret += [[(prevnr-len(rmlines)), addedlines, rmlines]]
    endif
    return ret
endfunction

function! auf#diff#parseChangedLines(diffpath) abort
    let hlines  = []
    let lnfirst = -1
    let deletelast = 0
    let i = 0
    let flines = readfile(a:diffpath)
    for line in flines
        if line ==# ''
            continue
        elseif line[0] ==# '@'
            let lnfirst = str2nr(line[4:stridx(line, ',')])
            continue
        elseif lnfirst == -1
            continue
        endif
        if line[0] ==# '-'
            let hlines += [lnfirst]
        endif
        if line[0] !=# '+'
            let lnfirst += 1
        endif
        if line ==# '\\ No newline at end of file' && i ==# len(flines)-2 && flines[i+1] ==# ''
            let deletelast = 1
        endif
        let i += 1
    endfor
    if deletelast && len(hlines)
        let hlines = hlines[0:-2]
    endif
    return hlines
endfunction

function! auf#diff#diffFiles(diffcmd, origf, modiff, difpath) abort
    let cmd = a:diffcmd . ' ' . a:origf . ' ' . a:modiff
    call auf#util#logVerbose('diffFiles: command> ' . cmd)
    let out = auf#util#execWithStdout(cmd)
    if v:shell_error == 0 " files are the same
        return [1, 0, v:shell_error]
    elseif v:shell_error == 1 " files are different
    else " error occurred
        return [0, 1, v:shell_error]
    endif
    call writefile(split(out, '\n'), a:difpath)
    return [0, 0, v:shell_error]
endfunction

function! auf#diff#filterPatchLinesRanged(filterdifcmd, line1, line2, origf, difpath) abort
    let cmd = a:filterdifcmd . ' -i ' . a:origf . ' --lines=' . a:line1 . '-' . a:line2 . ' ' . a:difpath
    call auf#util#logVerbose('filterPatchLinesRanged: filter-diff Command:' . cmd)
    let out = auf#util#execWithStdout(cmd)
    call writefile(split(out, '\n'), a:difpath)
endfunction

function! auf#diff#applyHunkInPatch(filterdifcmd, patchcmd, origf, difpath, line1, line2) abort
    call auf#diff#filterPatchLinesRanged(a:filterdifcmd, a:line1, a:line2, a:origf, a:difpath)
    let cmd = a:patchcmd . ' < ' . a:difpath
    call auf#util#logVerbose('applyHunkInPatch: patch Command:' . cmd)
    let out = auf#util#execWithStdout(cmd)
    return [0, v:shell_error]
endfunction

