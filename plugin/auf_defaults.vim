"
" This file contains default settings and all format program definitions and links these to filetypes

" vim-auf configuration variables
if !exists('g:auf_autoindent')
    let g:auf_autoindent = 1
endif

if !exists('g:auf_retab')
    let g:auf_retab = 1
endif

if !exists('g:auf_highlight_longlines')
    let g:auf_highlight_longlines = 1
endif

if !exists('g:auf_highlight_longlines_syntax')
    let g:auf_highlight_longlines_syntax = 'DiffChange'
endif

if !exists('g:auf_remove_trailing_spaces')
    let g:auf_remove_trailing_spaces = 1
endif

if !exists('g:auf_probe_formatter')
    let g:auf_probe_formatter = 1
endif

if !exists('g:auf_fallback_func')
    let g:auf_fallback_func = ''
endif

if !exists('g:auf_showdiff_synmatch')
    let g:auf_showdiff_synmatch = 'Todo'
endif

if !exists('g:auf_changedline_synmatch')
    let g:auf_changedline_synmatch = 'ErrorMsg'
endif

if !exists('g:auf_deepindent_max')
    let g:auf_deepindent_max = 4
endif

if !exists('g:auf_deepindent_synmatch')
    let g:auf_deepindent_synmatch = 'Underlined'
endif

if !exists('g:auf_highlight_pattern')
    " Don't highlight
    let g:auf_highlight_pattern = ''
    " Full line highlight
    let g:auf_highlight_pattern = '\(\%##LINENUM##l\)'
    " Highlight leading white-space
    let g:auf_highlight_pattern = '^\(\%##LINENUM##l\)\s\+'
    " Highlight all white-space within
    let g:auf_highlight_pattern = '\(\%##LINENUM##l\)\s'
    " Highlight white-space only when preceded by non-white
    let g:auf_highlight_pattern = '\(\%##LINENUM##l\)\zs\s\ze\S'
endif

if !exists('g:auf_changedline_pattern')
    " Highlight leading white-space
    let g:auf_changedline_pattern = '^\(\%##LINENUM##l\)\s\+'
    " Highlight white-space only when preceded by non-white
    let g:auf_changedline_pattern = '\(\%##LINENUM##l\)\zs\s\ze\S'
endif

if !exists('g:auf_deepindent_pattern')
    let g:auf_deepindent_pattern = '^\(\%##LINENUM##l\)\s\+\S'
endif

if !exists('g:auf_highlight_on_bufenter')
    let g:auf_highlight_on_bufenter = 0
endif

if !exists('g:auf_jitformat')
    let g:auf_jitformat = 1
endif

if !exists('g:auf_hijack_gq')
    let g:auf_hijack_gq = 1
endif

if !exists('g:auf_filetypes')
    " those defined to have a formatter
    let g:auf_filetypes = ',c,cpp,cs,css,dart,fortran,go,haskell,html,java,javascript,json,markdown,objc,perl,python,ruby,rust,scss,typescript,xhtml,xml,'
    " allow for *all*
    let g:auf_filetypes = '*'
endif

if !exists('g:auf_verbosemode')
    let g:auf_verbosemode = 0
endif

if !exists('g:auf_diffcmd')
    let g:auf_diffcmd = 'diff'
endif

if !exists('g:auf_filterdiffcmd')
    let g:auf_filterdiffcmd = 'filterdiff'
endif

if !exists('g:auf_patchcmd')
    let g:auf_patchcmd = 'patch'
endif

if !exists('g:auf_tempnames_prefix')
    let g:auf_tempnames_prefix = '/.__'
endif

" TODO:
" * When ranged :Auf is executed, highlight the lines in range wout touching
"    other lines' highlighting since file might contain different filetypes
" * Use conceal to mark wrong formatted lines
