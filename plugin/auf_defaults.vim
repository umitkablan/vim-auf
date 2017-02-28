"
" This file contains default settings and all format program definitions and links these to filetypes

" vim-auf configuration variables
if !exists('g:auf_autoindent')
    let g:auf_autoindent = 1
endif

if !exists('g:auf_retab')
    let g:auf_retab = 1
endif

if !exists('g:auf_remove_trailing_spaces')
    let g:auf_remove_trailing_spaces = 1
endif

if !exists('g:auf_verbosemode')
    let g:auf_verbosemode = 0
endif

" ****************
" Python
" ****************
if !exists('g:auffmt_autopep8')
    " Autopep8 will not do indentation fixes when a range is specified, so we
    " only pass a range when there is a visual selection that is not the
    " entire file. See #125.
    let g:auffmt_autopep8 = '"autopep8 -".(g:DoesRangeEqualBuffer(a:firstline, a:lastline) ? " --range ".a:firstline." ".a:lastline : "")." ".(&textwidth ? "--max-line-length=".&textwidth : "")." < ##INPUTSRC##"'
endif

" There doesn't seem to be a reliable way to detect if are in some kind of visual mode,
" so we use this as a workaround. We compare the length of the file against
" the range arguments. If there is no range given, the range arguments default
" to the entire file, so we return false if the range comprises the entire file.
function! g:DoesRangeEqualBuffer(first, last)
    return line('$') != a:last - a:first + 1
endfunction

" Yapf supports multiple formatter styles: pep8, google, chromium, or facebook
if !exists('g:auffmt_yapf_style')
    let g:auffmt_yapf_style = 'pep8'
endif
if !exists('g:auffmt_yapf')
    let g:auffmt_yapf = "'yapf --style=\"{based_on_style:'.g:auffmt_yapf_style.',indent_width:'.&shiftwidth.',column_limit:'.&textwidth.'}\" -l ##FIRSTLINE##-##LASTLINE##' < ##INPUTSRC##'"
endif

if !exists('g:aufformatters_python')
    let g:aufformatters_python = ['autopep8','yapf']
endif

" ****************
" C#
" ****************
if !exists('g:auffmt_astyle_cs')
    if filereadable('.astylerc')
        let g:auffmt_astyle_cs = '"astyle --mode=cs --options=.astylerc < ##INPUTSRC##"'
    elseif filereadable(expand('~/.astylerc')) || exists('$ARTISTIC_STYLE_OPTIONS')
        let g:auffmt_astyle_cs = '"astyle --mode=cs < ##INPUTSRC##"'
    else
        let g:auffmt_astyle_cs = '"astyle --mode=cs --style=ansi --indent-namespaces -pcH".(&expandtab ? "s".shiftwidth() : "t")." < ##INPUTSRC##"'
    endif
endif

if !exists('g:aufformatters_cs')
    let g:aufformatters_cs = ['astyle_cs']
endif

" *******************
" clang-format: C, C++, Objective-C
" *******************
if !exists('g:auffmt_clangformat')
    let s:configfile_def = "'clang-format -lines=##FIRSTLINE##:##LASTLINE## --assume-filename=\"'.expand('%:.').'\" -style=file \"##INPUTSRC##\"'"
    let s:noconfigfile_def = "'clang-format -lines=##FIRSTLINE##:##LASTLINE## --assume-filename=\"'.expand('%:.').'\" -style=\"{BasedOnStyle: WebKit, AlignTrailingComments: true, '.(&textwidth ? 'ColumnLimit: '.&textwidth.', ' : '').(&expandtab ? 'UseTab: Never, IndentWidth: '.shiftwidth() : 'UseTab: Always').'}\" \"##INPUTSRC##\"'"
    let g:auffmt_clangformat = 'g:ClangFormatConfigFileExists() ? (' . s:configfile_def . ') : (' . s:noconfigfile_def . ')'
endif

function! g:ClangFormatConfigFileExists()
    return len(findfile('.clang-format', expand('%:p:h').';')) || len(findfile('_clang-format', expand('%:p:h').';'))
endfunction

" ****************
" C
" ****************
if !exists('g:auffmt_astyle_c')
    if filereadable('.astylerc')
        let g:auffmt_astyle_c = '"astyle --mode=c --options=.astylerc < ##INPUTSRC##"'
    elseif filereadable(expand('~/.astylerc')) || exists('$ARTISTIC_STYLE_OPTIONS')
        let g:auffmt_astyle_c = '"astyle --mode=c < ##INPUTSRC##"'
    else
        let g:auffmt_astyle_c = '"astyle --mode=c --style=ansi -pcH".(&expandtab ? "s".shiftwidth() : "t")." < ##INPUTSRC##"'
    endif
endif

if !exists('g:aufformatters_c')
    let g:aufformatters_c = ['clangformat', 'astyle_c']
endif

" ****************
" C++
" ****************
if !exists('g:auffmt_astyle_cpp')
    if filereadable('.astylerc')
        let g:auffmt_astyle_cpp = '"astyle --mode=c --options=.astylerc < ##INPUTSRC##"'
    elseif filereadable(expand('~/.astylerc')) || exists('$ARTISTIC_STYLE_OPTIONS')
        let g:auffmt_astyle_cpp = '"astyle --mode=c < ##INPUTSRC##"'
    else
        let g:auffmt_astyle_cpp = '"astyle --mode=c --style=ansi -pcH".(&expandtab ? "s".shiftwidth() : "t")." < ##INPUTSRC##"'
    endif
endif

if !exists('g:aufformatters_cpp')
    let g:aufformatters_cpp = ['clangformat', 'astyle_cpp']
endif

" ****************
" Objective C
" ****************
if !exists('g:aufformatters_objc')
    let g:aufformatters_objc = ['clangformat']
endif

" ****************
" Java
" ****************
if !exists('g:auffmt_astyle_java')
    if filereadable('.astylerc')
        let g:auffmt_astyle_java = '"astyle --mode=java --options=.astylerc < ##INPUTSRC##"'
    elseif filereadable(expand('~/.astylerc')) || exists('$ARTISTIC_STYLE_OPTIONS')
        let g:auffmt_astyle_java = '"astyle --mode=java < ##INPUTSRC##"'
    else
        let g:auffmt_astyle_java = '"astyle --mode=java --style=java -pcH".(&expandtab ? "s".shiftwidth() : "t")." < ##INPUTSRC##"'
    endif
endif

if !exists('g:aufformatters_java')
    let g:aufformatters_java = ['astyle_java']
endif

" ****************
" Javascript
" ****************
if !exists('g:auffmt_jsbeautify_javascript')
    if filereadable('.jsbeautifyrc')
        let g:auffmt_jsbeautify_javascript = '"js-beautify -f ##INPUTSRC##"'
    elseif filereadable(expand('~/.jsbeautifyrc'))
        let g:auffmt_jsbeautify_javascript = '"js-beautify -f ##INPUTSRC##"'
    else
        let g:auffmt_jsbeautify_javascript = '"js-beautify -X -f ##INPUTSRC## -".(&expandtab ? "s ".shiftwidth() : "t").(&textwidth ? " -w ".&textwidth : "").""'
    endif
endif

if !exists('g:auffmt_pyjsbeautify_javascript')
    let g:auffmt_pyjsbeautify_javascript = '"js-beautify -X -".(&expandtab ? "s ".shiftwidth() : "t").(&textwidth ? " -w ".&textwidth : "")." -f ##INPUTSRC##"'
endif

if !exists('g:auffmt_jscs')
    let g:auffmt_jscs = '"jscs -x -n < ##INPUTSRC##"'
endif

if !exists('g:auffmt_standard_javascript')
    let g:auffmt_standard_javascript = '"standard --fix ##INPUTSRC##"'
endif

if !exists('g:auffmt_xo_javascript')
    let g:auffmt_xo_javascript = '"xo --fix ##INPUTSRC## -o ##OUTPUTSRC##"'
endif

if !exists('g:aufformatters_javascript')
    let g:aufformatters_javascript = [
                \ 'jsbeautify_javascript',
                \ 'pyjsbeautify_javascript',
                \ 'jscs',
                \ 'standard_javascript',
                \ 'xo_javascript'
                \ ]
endif

" ****************
" JSON
" ****************
if !exists('g:auffmt_jsbeautify_json')
    if filereadable('.jsbeautifyrc')
        let g:auffmt_jsbeautify_json = '"js-beautify -f ##INPUTSRC##"'
    elseif filereadable(expand('~/.jsbeautifyrc'))
        let g:auffmt_jsbeautify_json = '"js-beautify -f ##INPUTSRC##"'
    else
        let g:auffmt_jsbeautify_json = '"js-beautify -f ##INPUTSRC## -".(&expandtab ? "s ".shiftwidth() : "t")'
    endif
endif

if !exists('g:auffmt_pyjsbeautify_json')
    let g:auffmt_pyjsbeautify_json = '"js-beautify -".(&expandtab ? "s ".shiftwidth() : "t")." ##INPUTSRC##"'
endif

if !exists('g:aufformatters_json')
    let g:aufformatters_json = [
                \ 'jsbeautify_json',
                \ 'pyjsbeautify_json',
                \ ]
endif

" ****************
" HTML
" ****************
if !exists('g:auffmt_htmlbeautify')
    let g:auffmt_htmlbeautify = '"html-beautify -f ##INPUTSRC## -".(&expandtab ? "s ".shiftwidth() : "t")'
endif

if !exists('g:auffmt_tidy_html')
    let g:auffmt_tidy_html = '"tidy -q --show-errors 0 --show-warnings 0 --force-output --indent auto --indent-spaces ".shiftwidth()." --vertical-space yes --tidy-mark no -wrap ".&textwidth." ##INPUTSRC## -o ##OUTPUTSRC##"'
endif

if !exists('g:aufformatters_html')
    let g:aufformatters_html = ['htmlbeautify', 'tidy_html']
endif

" ****************
" XML
" ****************
if !exists('g:auffmt_tidy_xml')
    let g:auffmt_tidy_xml = '"tidy -q -xml --show-errors 0 --show-warnings 0 --force-output --indent auto --indent-spaces ".shiftwidth()." --vertical-space yes --tidy-mark no -wrap ".&textwidth'.' ##INPUTSRC## -o ##OUTPUTSRC##'
endif

if !exists('g:aufformatters_xml')
    let g:aufformatters_xml = ['tidy_xml']
endif

" ****************
" XHTML
" ****************
if !exists('g:auffmt_tidy_xhtml')
    let g:auffmt_tidy_xhtml = '"tidy -q --show-errors 0 --show-warnings 0 --force-output --indent auto --indent-spaces ".shiftwidth()." --vertical-space yes --tidy-mark no -asxhtml -wrap ".&textwidth'.' ##INPUTSRC## -o ##OUTPUTSRC##'
endif

if !exists('g:aufformatters_xhtml')
    let g:aufformatters_xhtml = ['tidy_xhtml']
endif

" ****************
" Ruby
" ****************
if !exists('g:auffmt_rbeautify')
    let g:auffmt_rbeautify = '"rbeautify ".(&expandtab ? "-s -c ".shiftwidth() : "-t")." ##INPUTSRC##"'
endif

if !exists('g:auffmt_rubocop')
    " The pipe to sed is required to remove some rubocop output that could not
    " be suppressed.
    let g:auffmt_rubocop = "'rubocop --auto-correct -o /dev/null -s '.bufname('%').' < ##INPUTSRC## \| sed /^===/d'"
endif

if !exists('g:aufformatters_ruby')
    let g:aufformatters_ruby = ['rbeautify', 'rubocop']
endif

" ****************
" CSS
" ****************
if !exists('g:auffmt_cssbeautify')
    let g:auffmt_cssbeautify = '"css-beautify -f - -s ".shiftwidth()." ##INPUTSRC##"'
endif

if !exists('g:aufformatters_css')
    let g:aufformatters_css = ['cssbeautify']
endif

" ****************
" SCSS
" ****************
if !exists('g:auffmt_sassconvert')
    let g:auffmt_sassconvert = '"sass-convert -F scss -T scss --indent " . (&expandtab ? shiftwidth() : "t")." ##INPUTSRC##"'
endif

if !exists('g:aufformatters_scss')
    let g:aufformatters_scss = ['sassconvert']
endif

" ****************
" Typescript
" ****************
if !exists('g:auffmt_tsfmt')
    let g:auffmt_tsfmt = "'tsfmt ##INPUTSRC## '.bufname('%')"
endif

if !exists('g:aufformatters_typescript')
    let g:aufformatters_typescript = ['tsfmt']
endif

" ****************
" Golang
" ****************
" Two definitions are provided for two versions of gofmt.
" See issue #59
if !exists('g:auffmt_gofmt_1')
    let g:auffmt_gofmt_1 = '"gofmt -tabs=".(&expandtab ? "false" : "true")." -tabwidth=".shiftwidth() ##INPUTSRC##'
endif

if !exists('g:auffmt_gofmt_2')
    let g:auffmt_gofmt_2 = '"gofmt ##INPUTSRC##"'
endif

if !exists('g:auffmt_goimports')
    let g:auffmt_goimports = '"goimports ##INPUTSRC##"'
endif

if !exists('g:aufformatters_go')
    let g:aufformatters_go = ['gofmt_1', 'goimports', 'gofmt_2']
endif

" ****************
" Rust
" ****************
if !exists('g:auffmt_rustfmt')
    let g:auffmt_rustfmt = '"rustfmt ##INPUTSRC##"'
endif

if !exists('g:aufformatters_rust')
    let g:aufformatters_rust = ['rustfmt']
endif

" ****************
" Dart
" ****************
if !exists('g:auffmt_dartfmt')
    let g:auffmt_dartfmt = '"dartfmt ##INPUTSRC##"'
endif

if !exists('g:aufformatters_dart')
    let g:aufformatters_dart = ['dartfmt']
endif

" ****************
" Perl
" ****************
if !exists('g:auffmt_perltidy')
    " use perltidyrc file if readable
    if (has('win32') && (filereadable('perltidy.ini') ||
                \ filereadable($HOMEPATH.'/perltidy.ini'))) ||
                \ ((has('unix') ||
                \ has('mac')) && (filereadable('.perltidyrc') ||
                \ filereadable('~/.perltidyrc') ||
                \ filereadable('/usr/local/etc/perltidyrc') ||
                \ filereadable('/etc/perltidyrc')))
        let g:auffmt_perltidy = '"perltidy -q -st ##INPUTSRC##"'
    else
        let g:auffmt_perltidy = '"perltidy --perl-best-practices --format-skipping -q ##INPUTSRC## "'
    endif
endif

if !exists('g:aufformatters_perl')
    let g:aufformatters_perl = ['perltidy']
endif

" ****************
" Haskell
" ****************
if !exists('g:auffmt_stylish_haskell')
    let g:auffmt_stylish_haskell = '"stylish-haskell ##INPUTSRC##"'
endif

if !exists('g:aufformatters_haskell')
    let g:aufformatters_haskell = ['stylish_haskell']
endif

" ****************
" Markdown
" ****************
if !exists('g:auffmt_remark_markdown')
    let g:auffmt_remark_markdown = '"remark --silent --no-color ##INPUTSRC##"'
endif

if !exists('g:aufformatters_markdown')
    let g:aufformatters_markdown = ['remark_markdown']
endif

" ****************
" Fortran
" ****************
if !exists('g:auffmt_fprettify')
    let g:auffmt_fprettify = '"fprettify --no-report-errors --indent=".&shiftwidth ##INPUTSRC##'
endif

if !exists('g:aufformatters_fortran')
    let g:aufformatters_fortran = ['fprettify']
endif

if !exists('g:auf_filetypes')
    let g:auf_filetypes = ',c,cpp,cs,css,dart,fortran,go,haskell,html,java,javascript,json,markdown,objc,perl,python,ruby,rust,scss,typescript,xhtml,xml,'
endif

if !exists('g:auf_autoindent')
    let g:auf_autoindent = 0
endif

if !exists('g:auf_showdiff_synmatch')
    let g:auf_showdiff_synmatch = 'ErrorMsg'
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

if !exists('g:auf_highlight_errs')
    let g:auf_highlight_errs = 1
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
