# NAME

zxbpp - Boriel BASIC compiler preprocessor

# SYNOPSIS

**zxbpp** [-h] [-o OUTPUT_FILE] [-d] [-e STDERR] [--arch ARCH]
  [--expect-warnings EXPECT_WARNINGS]
  [input_file]

# DESCRIPTION

**zxbpp** is the compiler preprocessor for Boriel BASIC language.

# OPTIONS

The program follows the usual GNU command line syntax, with long options
starting with two dashes ('-'). A summary of options is included below.

**-h, --help**
:   Show help message and exit.

**-o OUTPUT\_FILE, --output OUTPUT\_FILE**
:   Sets output file. Default is to output to console (STDOUT).

**-d, --debug**
:   Enable verbosity/debugging output. Additional -d increases verbosity/debug level.

**-e STDERR, --errmsg STDERR**
:   Error messages file. Standard error console by default (STDERR).

**--arch {zx48k,zxnext}**
:   Target architecture (defaults is'zx48k'). Available architectures: zx48k,zxnext

**--expect-warnings N**
:   Expects N warnings: first N warnings will be silenced.

# BUGS

The upstream BTS can be found at https://github.com/boriel-basic/zxbasic/issues.

# SEE ALSO

**zxbc**(1), **zxbasm**(1)

# AUTHOR

Copyleft (K) 2008, José Rodríguez-Rosa (a.k.a. Boriel) http://www.boriel.com.
:   Wrote the programs `zxbc`, `zxbasm` and `zxbpp`.

Guillermo Gutierrez <guillermo@gutierrez.dev>
:   Wrote this manpage for the Debian system.

# COPYRIGHT

Copyright © 2025 Guillermo Gutiérrez

This manual page was written for the Debian system (and may be used by
others).

Permission is granted to copy, distribute and/or modify this document under
the terms of the GNU General Public License, Version 2 or (at your option)
any later version published by the Free Software Foundation.

On Debian systems, the complete text of the GNU General Public License
can be found in /usr/share/common-licenses/GPL.
