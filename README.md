# vim-auf

## JIT format code with AUF on the fly and *only your changes*

While working in the professional domain you'll encounter coding guidelines and many code that is not aligned with this guideline; especially if it is forced manually by people or there are 2+ conflicting tastes / modules - we all have different tastes anyways. (Correct way to do such a thing is to give enough tooling to the programmers - a formatter that will automatically format code no matter how s/he types). There is also a sad news that some formatters will uglify some expressions, especially when the language you are using has many concepts ranging from macros to templates and user-defined operators (people could combine such features in crazily intelligent ways and resulting usage would be hard to reason or classify it into a formatting rule) - we should live in such an environment where we have human-styles as well as an automated hand intermixed.

If you are using an automated tool to reformat *all* code - you'll, many times, touch other people's lines and it will make you the blame for that line IF they don't complain about your change and make you revert.

Reformatting only your edits on-the-fly will make you forget about any formatting rule and take the burden off your shoulders as well as making you lazier and not type any whitespacing between expressions - AUF will take care anyways! When you see the format output live, you can change it very quickly if it makes it hard to read and let the formatter not touch this "manual formatting" again.

This plugin makes use of external formatter programs which are designed in UNIX philosophy and running in command line. Those programs are already well known/supported and already are actively used in other editors/IDEs. AUF will let you get those configurations directly from those environments and adapt quickly - no need to re-define them in another language. In order to utilize them by AUF, formatters at least should accept input path as argument and output to stdout. Yet it is always better to have those formatters get input and output paths as well as line range to format. The algorithm implemented here won't complain if the formatter is only-full-file and doesn't support line range - it will filter-out unnecessary formatted lines and still work on the code you touched.

While AUF introduces JIT formatting which will format only your edits, you still can reformat *all* file easily `:Auf!`(not preferred for our case). In order to still warn you about those wrong-format lines it uses line highlighting which is also configurable (`g:auf_showdiff_synmatch g:auf_highlight_pattern g:auf_changedline_synmatch g:auf_changedline_pattern`) and slides as you edit. Those wrong-format lines will be shown once you start editing (i.e. get out of the insert mode) and it won't distract you during insert mode.

When no formatter exists (or none is installed) for a certain filetype, vim-auf falls back by default to indenting, (using vim's auto indent functionality), retabbing and removing trailing whitespace working on touched lines only.

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
As highlighting style is configurable by patterns as above, these lines will float as you type - back and forth and settle after write. After write, actually, no full-recheck needs to be done. But, by default, code is rescanned fully just in case. To disable full-recheck after every write disable `g:auf_rescan_on_writepost [=1]` by setting it to 0 (default 1).
```vim
let g:auf_rescan_on_writepost = 0
```
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

The normal `:Auf` command will *only* highlight lines with wrong formatting where you can `:AufShowDiff` to see the diff-file of correctly-formatted to current.

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

If you have a composite filetype with dots (like `django.python` or `php.wordpress`),
vim-auf first tries to detect and use formatters for the exact original filetype, and
then tries the same for all supertypes occurring from left to right in the original filetype
separated by dots.

## Default formatter programs

Here is a list of formatter programs that are supported by default, and thus will be detected and used by vim when they are installed properly.

* `clang-format` for __C__, __C++__, __Objective-C__ (supports formatting ranges).
  Clang-format is a product of LLVM source builds.
  If you `brew install llvm`, clang-format can be found in /usr/local/Cellar/llvm/bin/.
  Vim-auf checks whether there exists a `.clang-format` or a `_clang-format` file up in
  the current directory's ancestry. Based on that it either uses that file or tries to match
  vim options as much as possible.
  Details: http://clang.llvm.org/docs/ClangFormat.html.

* `astyle` for __C#__, __C++__, __C__ and __Java__.
  Download it here: http://astyle.sourceforge.net/.
  *Important: version `2.0.5` or higher is required, since only those versions correctly support piping and are stable enough.*

* `autopep8` for __Python__ (supports formatting ranges).
  It's probably in your distro's repository, so you can download it as a regular package.
  For Ubuntu type `sudo apt-get install python-autopep8` in a terminal.
  Here is the link to the repository: https://github.com/hhatto/autopep8.
  And here the link to its page on the python website: http://pypi.python.org/pypi/autopep8/0.5.2.

* `yapf` for __Python__ (supports formatting ranges).
  It is readily available through PIP. Most users can install with the terminal command `sudo pip install yapf` or `pip --user install yapf`.
  YAPF has one optional configuration variable to control the formatter style.
  For example:
  ```vim
  let g:auffmt_yapf_style = 'pep8'
   ```
  `pep8` is the default value, or you can choose: `google`, `facebook`, `chromium`.

  Here is the link to the repository: https://github.com/google/yapf

* `js-beautify` for __Javascript__ and __JSON__.
  It can be installed by running `npm install -g js-beautify`.
  Note that `nodejs` is needed for this to work.
  The python version version is also supported by default, which does not need `nodejs` to run.
  Here is the link to the repository: https://github.com/einars/js-beautify.

* `JSCS` for __Javascript__. http://jscs.info/

* `standard` for __Javascript__.
  It can be installed by running `npm install -g standard` (`nodejs` is required). No more configuration needed.
  More information about the style guide can be found here: http://standardjs.com/.

* `xo` for __Javascript__.
  It can be installed by running `npm install -g xo` (`nodejs` is required).
  Here is the link to the repository: https://github.com/sindresorhus/xo.

* `html-beautify` for __HTML__.
  It is shipped with `js-beautify`, which can be installed by running `npm install -g js-beautify`.
  Note that `nodejs` is needed for this to work.
  Here is the link to the repository: https://github.com/einars/js-beautify.

* `css-beautify` for __CSS__.
  It is shipped with `js-beautify`, which can be installed by running `npm install -g js-beautify`.
  Note that `nodejs` is needed for this to work.
  Here is the link to the repository: https://github.com/einars/js-beautify.

* `typescript-formatter` for __Typescript__.
  `typescript-formatter` is a thin wrapper around the TypeScript compiler services.
  It can be installed by running `npm install -g typescript-formatter`.
  Note that `nodejs` is needed for this to work.
  Here is the link to the repository: https://github.com/vvakame/typescript-formatter.

* `sass-convert` for __SCSS__.
  It is shipped with `sass`, a CSS preprocessor written in Ruby, which can be installed by running `gem install sass`.
  Here is the link to the SASS homepage: http://sass-lang.com/.

* `tidy` for __HTML__, __XHTML__ and __XML__.
  It's probably in your distro's repository, so you can download it as a regular package.
  For Ubuntu type `sudo apt-get install tidy` in a terminal.

* `rbeautify` for __Ruby__.
  It is shipped with `ruby-beautify`, which can be installed by running `gem install ruby-beautify`.
  Note that compatible `ruby-beautify-0.94.0` or higher version.
  Here is the link to the repository: https://github.com/erniebrodeur/ruby-beautify.
  This beautifier developed and tested with ruby `2.0+`, so you can have weird results with earlier ruby versions.

* `rubocop` for __Ruby__.
  It can be installed by running `gem install rubocop`.
  Here is the link to the repository: https://github.com/bbatsov/rubocop

* `gofmt` for __Golang__.
  The default golang formatting program is shipped with the golang distribution. Make sure `gofmt` is in your PATH (if golang is installed properly, it should be).
  Here is the link to the installation: https://golang.org/doc/install

* `rustfmt` for __Rust__.
  It can be installed using `cargo`, the Rust package manager. Up-to-date installation instructions are on the project page: https://github.com/nrc/rustfmt/#installation.

* `dartfmt` for __Dart__.
  Part of the Dart SDK (make sure it is on your PATH). See https://www.dartlang.org/tools/dartfmt/ for more info.

* `perltidy` for __Perl__.
  It can be installed from CPAN `cpanm Perl::Tidy` . See https://metacpan.org/pod/Perl::Tidy and http://perltidy.sourceforge.net/ for more info.

* `stylish-haskell` for __Haskell__
  It can be installed using [`cabal`](https://www.haskell.org/cabal/) build tool. Installation instructions are available at https://github.com/jaspervdj/stylish-haskell#installation

* `remark` for __Markdown__.
  A Javascript based markdown processor that can be installed with `npm install -g remark`. More info is available at https://github.com/wooorm/remark.

* `fprettify` for modern __Fortran__.
  Download from [official repository](https://github.com/pseewald/fprettify). Install with `./setup.py install` or `./setup.py install --user`.

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
  \ 'ranged'    : 0,                   " Tell whether formatter supports line range
  \ 'fileout'   : 1                    " Is formatter capable of outputting to a file or not (stdout)
  \ }

function! auf#formatters#mytypefmt0#define() abort
  return s:definition
endfunction

" Should return the command line string to execute the formatter.
" The declarations we made above and this function's return should sync; meaning if file
" output declared to be 0, then outpath below should not be used and returned command
" line should be outputting to standard output
function! auf#formatters#mytypefmt0#cmd(ftype, inpath, outpath, line0, line1) abort
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

" Register our formatter to the auf-registry
call auf#registry#RegisterFormatter(s:definition)
```

## Contributing

Pull requests are welcome.
Any feedback is welcome.
If you have any suggestions on this plugin or on this readme, if you have some nice default
formatter definition that can be added to the defaults, or if you experience problems, please
contact me by creating an issue in this repository.
