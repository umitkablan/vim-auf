# vim-auf

## JIT format code with AUF on the fly and *only your changes* with ultimate Auf!

While working in the professional domain you'll encounter coding guidelines and many code that is not aligned with this guideline; especially if it is forced manually by people or there are 2+ conflicting tastes / modules - we all have different tastes anyways. (Correct way to do such a thing is to give enough tooling to the programmers - a formatter that will automatically format code no matter how s/he types). There is also a sad news that some formatters will uglify some expressions, especially when the language you are using has many concepts ranging from macros to templates and user-defined operators (people could combine such features in crazily intelligent ways and resulting usage would be hard to reason or classify it into a formatting rule) - we should live in such an environment where we have human-styles as well as an automated hand intermixed.

If you are using an automated tool to reformat *all* code - you'll, many times, touch other people's lines and it will make you the blame for that line IF they don't complain about your change and make you revert.

Reformatting only your edits on-the-fly will make you forget about any formatting rule and take the burden off your shoulders as well as making you lazier and not type any whitespacing between expressions - AUF will take care anyways! When you see the format output live, you can change it very quickly if it makes it hard to read and let the formatter not touch this "manual formatting" again.

This plugin makes use of external formatter programs which are designed in UNIX philosophy and running in command line. Those programs are already well known/supported and already are actively used in other editors/IDEs. AUF will let you get those configurations directly from those environments and adapt quickly - no need to re-define them in another language. In order to utilize them by AUF, formatters at least should accept input path as argument and output to stdout. Yet it is always better to have those formatters get input and output paths as well as line range to format. The algorithm implemented here won't complain if the formatter is only-full-file and doesn't support line range - it will filter-out unnecessary formatted lines and still work on the code you touched.

While AUF introduces JIT formatting which will format only your edits, you still can reformat *all* file easily `:Auf!`(not preferred for our case). In order to still warn you about those wrong-format lines it uses line highlighting which is also configurable (`g:auf_showdiff_synmatch g:auf_highlight_pattern g:auf_changedline_synmatch g:auf_changedline_pattern`) and slides as you edit. Those wrong-format lines will be shown once you start editing (i.e. get out of the insert mode) and it won't distract you during insert mode.

When no formatter exists (or none is installed) for a certain filetype, vim-auf falls back by default to indenting, (using vim's auto indent functionality), retabbing and removing trailing whitespace working on touched lines only.

Auf also can highlight lines longer than configured textwidth of the buffer - eliminating your vimrc settings/adding sensible defaults.

## Features in a Nutshell
 - Works with basic command line formatters (clang-format, js-beautify etc.)
 - Format only touched lines after a save - JITing.
 - Avoid formatting with a bang `:w!` - accept as is.
 - Configurable and sufficient highlighting - changed (to be formatted) lines, wrong-format lines.
 - Already defined popular formatters for different filetypes.
 - Pure VimScript.
 - Automatic formatter selection based on formatter dot-files in project directory - use those settings.
 - Vim settings (buffer or global) are respected and defined into formatter parameters.

## How to install

This plugin is supported by Vim 7.4+ and is pure Vimscript i.e. has no `+python`, `+eval` or other feature dependency than Vimscript and supporting command line programs.

As the main logic of finding unsaved lines or filtering is built on diff-file processing, you need to install diff(.exe), filterdiff(.exe), and patch(.exe) utilities (some call it diff-utils). Windows users might need to install Cygwin with those diff-utils inside.

It is highly recommended to use a plugin manager such as [Vundle](https://github.com/VundleVim/Vundle.vim), [vim-plug](https://github.com/junegunn/vim-plug), or [pathogen.vim](https://github.com/tpope/vim-pathogen), since this makes it easy to update plugins or uninstall them. It also keeps your .vim directory clean.

For Plug, put this in your .vimrc
```vim
Plug 'umitkablan/vim-auf'
```
Then restart vim and run `:PlugInstall`.

## How to use

First you should install an external program that can format code of the programming language you are using. This can either be one of the programs that are listed below as default programs, or a custom program. For default programs, AUF knows for which filetypes it can be used. For using a custom formatter program, read the text below *How can I change the behaviour of formatters, or add one myself?* If the formatter program you want to use is installed in one of the following ways, vim automatically detects it:

* It suffices to make the formatter program globally available, which is the case if you install it via your package manager.
* Alternatively you can append program location to $PATH environment variable before starting VIM

## Automation and Configuration

Since AUF should be backed by command line formatters, it will be active only in filetypes defined in `g:auf_filetypes [='*']`. It defaults to work on all types of regular files - don't be afraid it will retab/indent at worst and it helps. You can give comma separated values to that, `',c,cpp,java,html,'`; an empty string will disable Auf automation `''`.

Auf will try all defined formatters (of the buffer filetype) until one succeeds and use it. If auto-inferring of the formatter is enabled (default enabled) `g:auf_probe_formatter [=1]` it will seek configuration file (e.g. .clang-format) in/above the directories of file and set it without try-running others. Still, if you want limited set of formatters to be tried/probed, you define `let g:aufformatters_<filetype> = ['fmt_0', 'fmt_1']` like, for example, `let g:aufformatters_cpp = ['clangformat', 'astyle']`.

During typing if you encounter a bad style from formatter, you can undo and `:write!` with a bang easily to skip formatting and accept as is. Auf will not touch this line after it is written. This situation should occur rare - and don't forget to `:w!`.

`g:auf_jitformat [=1]` controls whether JITing on-the-fly is enabled with precedence to buffer-local `b:auf_jitformat [default undefined]`. Use the buffer-local version to disable for certain filetypes/conditions you sketch.

`g:auf_hijack_gq [=1]` will enable `gq` a 'motion' - it would be handy and Vim-way to format a piece of code with `gq<motion>`, so it is enabled by default.

`g:auf_showdiff_synmatch [='Todo']` is the error Syntax to use for wrongly-formatted lines and `g:auf_highlight_pattern` is the coloring pattern to apply on that line.
Likely, `g:auf_changedline_synmatch [='ErrorMsg']` is the error Syntax to use for not yet checked newly-edited lines and `g:auf_changedline_pattern` is the coloring pattern to apply on those lines. Those patterns could be, e.g.:
```vim
    " Don't highlight
    let g:auf_highlight_pattern = ''
    " Full line highlight
    let g:auf_highlight_pattern = '$'

    " Highlight leading white-space
    let g:auf_changedline_pattern = '^\(\%##LINENUM##l\)\s\+'
    " Highlight all white-space within
    let g:auf_changedline_pattern = '\(\%##LINENUM##l\)\s'
```
As highlighting style is configurable by patterns as above, these lines will float as you type - back and forth and settle after write.

Remember that when no formatter program exists for a certain filetype, AUF falls back by default to indenting, retabbing and removing trailing whitespace - of course _only_ the lines you touched. This will fix at least the most basic things, according to Vim's indentfile for that filetype. To disable the fallback to Vim's indent file, retabbing and removing trailing whitespace, set the following variables to 0 which default to 1 and gives precedence to their `b:` variables:
```vim
let g:auf_autoindent = 0
let g:auf_retab = 0
let g:auf_remove_trailing_spaces = 0
```
To disable or re-enable these option for specific buffers, use the buffer local variants: `b:auf_autoindent`, `b:auf_retab` and `b:auf_remove_trailing_spaces` which has precedence over global counterparts:
```vim
autocmd FileType vim,tex let [b:auf_autoindent, b:auf_retab] = [0,0]
```
Auf is capable of highlighting lines longer than `&textwidth`. With `g:auf_highlight_longlines` configuration you can disable or select a style of highlighting long lines (of course if textwidth is defined and greater than zero):
```vim
" 0-> disable
" 1-> draw vertical line at textwidth
" 2-> mark longer parts with 'g:auf_highlight_longlines_syntax'
let g:auf_highlight_longlines = 1 " default
```
If `g:auf_highlight_longlines` value is `2` then you can set which syntax name to use with `g:auf_highlight_longlines_syntax [= 'DiffChange']` configuration.

You can, of course, manually autoindent, retab or remove trailing whitespace with the following respective commands:
```vim
<line_num>G=<movement>
:<range>retab
:<range>s[ubstitute]/\s\+$//g
```
`g:auf_diffcmd = 'diff'`, `g:auf_filterdiffcmd = 'filterdiff'`, and `let g:auf_patchcmd = 'patch'` are helpful when your diff-utils have different program names or path. Note that these variables are unlikely to be set.

## Commands

When you have installed the formatter you need, you can format the *entire* buffer with the command
`:Auf!`. You can provide the command with a filetype such as `:Auf! json`, default is the buffer's `&filetype`. This command could also be used in ranged mode which gives you the flexibility to format any embedded type like Javascript inside HTML.

The normal `:Auf` command will *only* highlight lines with wrong formatting where you can `:<line1>,<line2>AufShowDiff[!]` to see the diff-file of correctly-formatted to current. Default is to see the corrected version of current line where `:AufShowDiff` supports `range` and `!` - with bang all file corrected lines will be shown. If selected line format is correct then FULL difference is shown like `!`.

`:AufJIT [filetype]` command will JIT-format your recent *unsaved* changes, which is almost never will be used since it is automatically triggered by the plugin if not configured otherwise.

Note that these commands are for manual intervention and normally you won't need them. If you still want to use your strokes to format instead of relying on AUF automatic updates, then disable them as told above configuration section and something like:
```vim
" I am a manual guy
noremap <F3> :Auf!<CR>
```
```vim
" JIT only cpp files
au BufWritePre cpp :AufJIT
```
For each filetype, vim-auf has a list of applicable formatters. If you have multiple formatters installed that are supported for some filetype, AUF tries all formatters in this list of applicable formatters, until one succeeds. You can set this list manually in your vimrc (see section *How can I change the behaviour of formatters, or add one myself?*, or change the formatter with the highest priority by the commands `:AufNextFormatter` and `:AufPrevFormatter`. To print the currently selected formatter use `:AufCurrFormatter`. These latter commands are mostly useful for debugging purposes.

## Supported Formatters

'Ranged' section only shows if the ranged formatting is supported by the command line program - best
cooperation. Otherwise `Auf` already tries to filter &/ diff and support ranged format.

| Name                      | Language(s)         | Ranged? | Probe Files        | Note                                          |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [clang-format](http://clang.llvm.org/docs/ClangFormat.html)         | C, C++, Objective-C | RANGED  | [._]clang-format   |                                            |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [astyle](http://astyle.sourceforge.net/)               | C, C++, Java, C#    | NO      | .astylerc          | Only 2.0.5 or higher is stable enough         |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [uncrustify](http://uncrustify.sourceforge.net/)           | C, C++, Java, C#    | NO      | [.]uncrustify.cfg  |                                               |
|                           | Objective-C, Pawn   |         |                    |                                               |
|                           | Vala                |         |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [autopep8](http://pypi.python.org/pypi/autopep8)             | Python              | NO      |                    | Supports range as advertised but doesn't work |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [yapf](https://github.com/google/yapf)                 | Python              | RANGED  |                    | let g:auffmt_yapf_style [='pep8'] = 'facebook'|'google'|'chromium' |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [js-beautify](https://github.com/einars/js-beautify)          | Javascript, JSON    | NO      | .jsbeautifyrc      |                                              |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [jscs](http://jscs.info/)                 | Javascript          | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [standard](http://standardjs.com/)             | Javascript          | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [xo](https://github.com/sindresorhus/xo)                   | Javascript          | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [prettier](https://github.com/prettier/prettier)             | Javascript, JSON,   | RANGED  | .prettierrc        |                                               |
|                           | Flow, CSS, Less,    |         | prettier.config.js |                                               |
|                           | SCSS, Markdown,     |         |                    |                                               |
|                           | Typescript          |         |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [fixjson](https://github.com/rhysd/fixjson)              | JSON                | NO      |                    |                                              |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [html-beautify](https://github.com/einars/js-beautify)        | HTML                | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| tidy                      | HTML, XHTML, XML    | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [css-beautify](https://github.com/einars/js-beautify)         | CSS                 | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [tsfmt](https://github.com/vvakame/typescript-formatter)                | Typescript          | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [sass-convert](http://sass-lang.com/)         | SCSS                | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [rbeautify](https://github.com/erniebrodeur/ruby-beautify)            | Ruby                | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [rubocop](https://github.com/bbatsov/rubocop)              | Ruby                | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [gofmt](https://golang.org/doc/install)                | Go                  | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [goimports](https://golang.org/doc/install)            | Go                  | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [rustfmt](https://github.com/nrc/rustfmt/#installation)              | Rust                | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [dartfmt](https://www.dartlang.org/tools/dartfmt/)              | Dart                | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [perltidy](https://metacpan.org/pod/Perl::Tidy)             | Perl                | NO      | .perltidyrc        |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [stylish-haskell](https://github.com/jaspervdj/stylish-haskell#installation)      | Haskell             | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [remark](https://github.com/wooorm/remark)               | Markdown            | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [fprettify](https://github.com/pseewald/fprettify)            | FORTRAN             | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [shfmt](https://github.com/mvdan/sh#shfmt)                | sh                  | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [sqlparse](https://github.com/andialbrecht/sqlparse)             | SQL                 | NO      |                    |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |
| [fsqlf](https://github.com/dnsmkl/fsqlf)                | SQL                 | NO      | [._]fsqlf.conf     |                                               |
| ------------------------- | ------------------- | ------- | ------------------ | --------------------------------------------- |

## Debugging

If you're struggling with getting a formatter to work, it may help to set AUF in
verbose-mode. AUF will then output errors on formatters that failed.
```vim
let g:auf_verbosemode=1
" OR:
let verbose=1
```

## How can I change the behaviour of formatters, or add one myself?

If you need a formatter that is not among the defaults, or if you are not satisfied with the default formatting behaviour that is provided by AUF, you can define it yourself.
*The formatter program, at least should be able to receive file input argument and output to standard output. It is better to also have file output argument as well as line range to specify which lines to format.*

#### Autoload module as a formatter definition

Formatter definitions should be implemented in Vimscript inside autoload/auf/formatters/ directory - check already implemented definitions for a sample.

#### Scaffolding for new formatter

```vim
"
" File autoload/auf/formatters/mytypefmt0.vim
"
if exists('g:loaded_auffmt_mytypefmt0_definition') || !exists('g:loaded_auf_registry_autoload')
  finish
endif
let g:loaded_auffmt_mytypefmt0_definition = 1

let s:definition = {
  \ 'ID'        : 'mytypefmt0',        " ID is the basename of the autoload/* file and unique
  \ 'executable': 'mytypefmt',         " Executable name
  \ 'filetypes' : ['mytype', 'mytyp'], " All types this formatter activates for
  \ 'probefiles': ['.mytyp', '_mytyp'] " Probe those to auto-set formatter for project. OPTIONAL.
  \ }

function! auf#formatters#mytypefmt0#define() abort
  return s:definition
endfunction

" Should return the command line arguments for executable.
" Note that no line range yet.
" 'confpath' will be filled only if 'probefiles' is defined above
" and is found in directory hierarchy
function! auf#formatters#mytypefmt0#cmdArgs(ftype, confpath) abort
  let mode = ''
  if a:ftype ==# 'mytype'
    let mode = '-m mytype'
  elseif a:ftype ==# 'mytyp'
    let mode = '-m mytyp'
  else
    " Not possible to get to here
    return 'invalid!!!'
  endif
  return 'mytypefmt ' . a:inpath . ' ' . mode . ' -o ' . a:outpath
endfunction

" Return ranged addition of the passed command line.
" OPTIONAL: If not defined it means this formatter doesn't support RANGE.
function! auf#formatters#mytypefmt0#cmdAddRange(cmd, line0, line1) abort
    return a:cmd . ' -lines ' . a:line0 . ' ' . a:line1 " say it supports -lines argument
endfunction

" Return filepath-added command as extended from 'cmd' base
function! auf#formatters#mytypefmt0#cmdAddOutfile(cmd, outpath) abort
    return a:cmd . ' -o ' . a:outpath " say it supports -o argument
endfunction

" Register our formatter to the auf-registry
call auf#registry#RegisterFormatter(s:definition)
```

## Contributing

Pull requests are welcome.
Any feedback is welcome.
If you have any suggestions on this plugin or on this readme, if you have some nice default
formatter definition that can be added to the defaults, or if you experience problems, please
contact me by creating an issue in this repository.
