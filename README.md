# vim-auf

## JIT format code with AUF on the fly and *only your changes*

While working in the professional domain you'll encounter coding guidelines and many code that is not aligned with this guideline; especially if it is forced manually by people or there are 2+ conflicting tastes / modules - we all have different tastes anyways. (Correct way to do such a thing is to give enough tooling to the programmers - a formatter that will automatically format code no matter how s/he types). There is also a sad news that some formatters will uglify some expressions, especially when the language you are using has many concepts ranging from macros to templates and user-defined operators (people could combine such features in crazily intelligent ways and resulting usage would be hard to reason or classify it into a formatting rule) - we should live in such an environment where we have human-styles as well as an automated hand intermixed.

If you are using an automated tool to reformat *all* code - you'll, many times, touch other people's lines and it will make you the blame for that line IF they don't complain about your change and make you revert.

Reformatting only your edits on-the-fly will make you forget about any formatting rule and take the burden off your shoulders as well as making you lazier and not type any whitespacing between expressions - AUF will take care anyways! When you see the format output live, you can change it very quickly if it makes it hard to read and let the formatter not touch this "manual formatting" again.

This plugin makes use of external formatter programs which are designed in UNIX philosophy and running in command line. Those programs are already well known/supported and already are actively used in other editors/IDEs. AUF will let you get those configurations directly from those environments and adapt quickly - no need to re-define them in another language. In order to utilize them by AUF, formatters at least should accept input path as argument and output to stdout. Yet it is always better to have those formatters get input and output paths as well as line range to format. The algorithm implemented here won't complain if the formatter is only-full-file and doesn't support line range - it will filter-out unnecessary formatted lines and still work on the code you touched.

While AUF introduces JIT formatting which will format only your edits, you still can reformat *all* file easily (not preferred for our case). In order to still warn you about those wrong-format lines it uses line highlighting which is also configurable and slides as you edit. Those wrong-format lines will be shown once you start editing (i.e. get out of the insert mode) and it won't distract you during insert mode.

When no formatter exists (or none is installed) for a certain filetype, vim-auf falls back by default to indenting, (using vim's auto indent functionality), retabbing and removing trailing whitespace.

## How to install

This plugin is supported by Vim 7.4+ and is pure Vimscript i.e. has no python (or any other language dependency). Only Vim feature that we need, currently, is +eval, you can check it with :version command within Vim.

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

Since AUF should be backed by command line formatters, it will be active only in filetypes defined in `g:auf_filetypes`. Naturally below options are all applicable for these filetypes - they are no-use otherwise. You can check those types by typing `:let g:auf_filetypes` in Vim.

`g:auf_jitformat = 1` controls whether JITing on-the-fly is enabled. During typing if you encounter a bad style from formatter, you can temporarily set this to `0` and `:write` and then reset to `1` and go on typing. This situations should occur rare - otherwise your formatter has a bug or AUF misses something.

While AUF doesn't show erronous lines after opening a file, `g:auf_highlight_on_bufenter = 0` variable will enable it to show it from very beginning.

`g:auf_hijack_gq = 1` will enable `gq` a 'motion' - it would be easy and Vim-way to format a piece of code with `gq<motion>`, so it is enabled by default.

`g:auf_showdiff_synmatch = 'ErrorMsg'` is the error Syntax to use for wrongly-formatted lines and `g:auf_highlight_pattern = '\(\%##LINENUM##l\)\s'` is the coloring pattern to apply on that line.
```vim
    " Don't highlight
    let g:auf_highlight_pattern = ''
    " Full line highlight
    let g:auf_highlight_pattern = '\(\%##LINENUM##l\)'
    " Highlight leading white-space
    let g:auf_highlight_pattern = '^\(\%##LINENUM##l\)\s\+'
    " Highlight all white-space within
    let g:auf_highlight_pattern = '\(\%##LINENUM##l\)\s'
```
`g:auf_diffcmd = 'diff'`, `g:auf_filterdiffcmd = 'filterdiff'`, and `let g:auf_patchcmd = 'patch'` are helpful when your diff-utils have different program names or path.

Remember that when no formatter programs exists for a certain filetype, AUF falls back by default to indenting, retabbing and removing trailing whitespace. This will fix at least the most basic things, according to Vim's indentfile for that filetype. To disable the fallback to Vim's indent file, retabbing and removing trailing whitespace, set the following variables to 0:
```vim
let g:auf_autoindent = 0
let g:auf_retab = 0
let g:auf_remove_trailing_spaces = 0
```
To disable or re-enable these option for specific buffers, use the buffer local variants: `b:auf_autoindent`, `b:auf_retab` and `b:auf_remove_trailing_spaces`.

So to disable autoindent for filetypes that have incompetent indent files, use:
```vim
autocmd FileType vim,tex let b:auf_autoindent=0
```
You can manually autoindent, retab or remove trailing whitespace with the following respective
commands.
```vim
gg=G
:retab
:RemoveTrailingSpaces
```

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

#### Basic definitions

The formatter programs that available for a certain `<filetype>` are defined in `g:aufformatters_<filetype>`. This is a list containing string identifiers, which point to corresponding formatter definitions. The formatter definitions themselves are defined in `g:auffmt_<identifier>` as a string expression. Defining any of these variable manually in your .vimrc, will override the default value, if existing.

For example, a complete definition in your .vimrc for C# files could look like this:
```vim
let g:auffmt_my_custom_cs = '"astyle --mode=cs --style=ansi -pcHs4 < ##INPUTSRC##"'
let g:aufformatters_cs = ['my_custom_cs']
```
In this example, `my_custom_cs` is the identifier for our formatter definition. `##INPUTSRC##` is the file input path to feed the formatter. It will be better to have also `##OUTPUTSRC##` as file output, `##FIRSTLINE##` and `##LASTLINE##` to identify which range to format - but not necessary. The first line defines how to call the external formatter, while the second line tells AUF that this is the only formatter that we want to use for C# files.

*Please note the double quotes in `g:auffmt_my_custom_cs`*. This allows you to define the arguments dynamically (and what makes AUF to seek for `+eval` feature):
```vim
let g:auffmt_my_custom_cs = '"--mode=cs --style=ansi -pcHs".&shiftwidth." < ##INPUTSRC##"'
let g:aufformatters_cs = ['my_custom_cs']
```
Please notice that `g:auffmt_my_custom_cs` contains an expression that can be evaluated (`+eval`), as required. As you see, this allows us to dynamically define some parameters. In this example, the indent width that astyle will use, depends on the buffer local value of `&shiftwidth`, instead of being fixed at 4. So if you're editing a csharp file and change the `shiftwidth` (even at runtime), the `g:auffmt_my_custom_cs` will change correspondingly.

For the default formatter program definitions, the options `expandtab`, `shiftwidth` and `textwidth` are taken into account whenever possible. This means that the formatting style will match your current vim settings as much as possible. You can have look look at the exact default definitions for more examples. They are defined in `vim-auf/plugin/auf_defaults.vim`. As a small side note, in the actual defaults the function `shiftwidth()` is used instead of the property. This is because it falls back to the value of `tabstop` if `shiftwidth` is 0.

If you have a composite filetype with dots (like `django.python` or `php.wordpress`), AUF internally replaces the dots with underscores so you can specify formatters through `g:auf_django_python` and so on.

To override these options for a local buffer, use the buffer local variants: `b:auf_<filetype>` and `b:auffmt_<identifier>`. This can be useful, for example, when working with different projects with conflicting formatting rules, with each project having settings in its own vimrc or exrc file:
```vim
let b:auffmt_custom_c='"astyle --mode=c --suffix=none --options=/home/user/special_project/astylerc < ##INPUTSRC##"'
let b:aufformatters_c = ['custom_c']
```
#### Ranged definitions

If your format program supports formatting specific ranges, you can provide a format definition which allows to make use of this. The first and last line of the current range can be retrieved by the placeholders `##FIRSTLINE##` and `##LASTLINE##`. They default to the first and last line of your file, if no range was explicitly specified. So, a ranged definition could look like this:
```vim
let g:auffmt_autopep8 = "'autopep8 --range ##FIRSTLINE##-##LASTLINE## < ##INPUTSRC##'"
let g:aufformatters_python = ['autopep8']
```
Note that AUF is not dependant on ranged definitions to make ranged formats since it uses diff-tools to 'range'ify those formatters which are not. You can use line ranges on any formatter having at least file input parameter. (But still, if it supports range and file output parameters please define them as well)

## Contributing

Pull requests are welcome.
Any feedback is welcome.
If you have any suggestions on this plugin or on this readme, if you have some nice default
formatter definition that can be added to the defaults, or if you experience problems, please
contact me by creating an issue in this repository.
