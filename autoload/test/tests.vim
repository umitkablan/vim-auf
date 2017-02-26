
function! s:assertArrays(expect, arr) abort
    if type(a:expect) != type(a:arr)
        echoerr 'Expected type:' . type(a:expect) . ' not met with:' . type(a:arr)
        return 0
    endif
    if len(a:expect) != len(a:arr)
        echoerr 'Expected length:' . len(a:expect) . ' not met with:' . len(a:arr)
        return 0
    endif
    let [i, ret] = [0, 1]
    while i < len(a:expect)
        let e = a:expect[i]
        let a = a:arr[i]
        if type(e) !=# type(a)
            echoerr 'Expected type at ' . i . ' is ' . type(e) . ' not met with ' . type(a)
            let ret = 0
            let i += 1
            continue
        endif
        if type(e) == type([])
            let ret = s:assertArrays(e, a)
        else
            if e != a
                echoerr 'Expected value:''' . e . ''' not met with ''' . a . ''''
                let ret = 0
            endif
        endif
        let i += 1
    endwhile
    return ret
endfunction

function! TestAll() abort
    let all_diff_files = [
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/01_one_line_add_at_the_beginning.diff',
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/02_one_line_rm_at_beginning.diff',
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/03_add_and_rm_from_top.diff',
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/04_rm_and_add_from_top.diff',
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/05_replace_at_top_and_rm.diff',
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/06_replace_at_top_and_add.diff',
        \'/Users/i328658/.vim/packs/vim-auf/autoload/test/07_add_firstline_change_second.diff'
    \ ]
    let all_expect_results = [
        \ [[1,0,1,['#include <ctype.h>']]],
        \ [[1,1,0,[]]],
        \ [[1,0,1,['#include <ctype.h>']], [3,1,0,[]]],
        \ [[1,1,0,[]], [4,0,1,['#include <ctype.h>']]],
        \ [[1,1,1,['#include <ctype.h>']], [6,2,0,[]]],
        \ [[1,1,1,['#include <stdexcept>']], [6,0,2,['#include <ctype.h>','']]],
        \ [[1,2,1,['#include <sstream>']]],
    \ ]
    let i = 0
    while i < len(all_expect_results)
        let res = s:assertArrays(all_expect_results[i], auf#diff#parseDiffForHunks(all_diff_files[i]))
        if !res
            echoerr 'Failed test i:' . i . ' test file:' . all_diff_files[i] . ' due to error'
            break
        endif
        let i += 1
    endwhile
endfunction
