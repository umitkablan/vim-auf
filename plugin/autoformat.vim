
if g:autoformat_diffcmd == "" || !executable(g:autoformat_diffcmd)
    autocmd VimEnter *
        \ call s:echoErrorMsg("Autoformat: Can't start! \
            \Couldn't locate 'diff' program (defined in g:autoformat_diffcmd as '"
            \ . g:autoformat_diffcmd . "').")
    finish
endif
if g:autoformat_filterdiffcmd == "" || !executable(g:autoformat_filterdiffcmd)
    autocmd VimEnter *
        \ call s:echoErrorMsg("Autoformat: Can't start! \
            \Couldn't locate 'filterdiff' program (defined in g:autoformat_filterdiffcmd as '"
            \ . g:autoformat_filterdiffcmd . "').")
    finish
endif

let g:autoformat_diffcmd .= " -u "

execute "highlight def link AutoformatErrLine " . g:autoformat_showdiff_synmatch

" Save and recall window state to prevent vim from jumping to line 1: Beware
" that it should be done here due to <line1>,<line2> range.
command! -nargs=? -range=% -complete=filetype -bang -bar Autoformat
    \ let ww=winsaveview()|<line1>,<line2>call autoformat#TryAllFormatters(<bang>0, <f-args>)|call winrestview(ww)
command! -nargs=0 -bar AutoformatJIT call autoformat#justInTimeFormat("AutoformatErrLine")

" Create commands for iterating through formatter list
command! NextFormatter call autoformat#NextFormatter()
command! PreviousFormatter call autoformat#PreviousFormatter()
command! CurrentFormatter call autoformat#CurrentFormatter()

command! AutoformatShowDiff call autoformat#ShowDiff()
