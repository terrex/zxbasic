# NAME

zxbasm - Boriel BASIC assembler

# SYNOPSIS

**zxbasm** [-h] [-d] [-O OPTIMIZATION_LEVEL] [-o OUTPUT_FILE] [-T] [-t]
  [-B] [-a] [-e STDERR] [-M MEMORY_MAP] [-b] [-N] [--version]
  PROGRAM.asm

# DESCRIPTION

**zxbc** is the assembler for Boriel BASIC language.

# OPTIONS

The program follows the usual GNU command line syntax, with long options
starting with two dashes ('-'). A summary of options is included below.

**-h, --help**
:   Show help message and exit.

**-d, --debug**
:   Enable verbosity/debugging output

**-O OPTIMIZATION\_LEVEL, --optimize OPTIMIZATION\_LEVEL**
:   Sets optimization level. 0 = None

**-o OUTPUT\_FILE, --output OUTPUT\_FILE**
:   Sets output file. Default is input filename with .bin extension

**-T, --tzx**
:   Sets output format to tzx (default is .bin)

**-t, --tap**
:   Sets output format to tzx (default is .bin)

**-B, --BASIC**
:   Creates a BASIC loader which load the rest of the CODE. Requires -T ot -t.

**-a, --autorun**
:   Sets the program to auto run once loaded (implies --BASIC).

**-e STDERR, --errmsg STDERR**
:   Error messages file (standard error console by default).

**-M MEMORY\_MAP, --mmap MEMORY\_MAP**
:   Generate label memory map.

**-b, --bracket**
:   Allows brackets only for memory access and indirections.

**-N, --zxnext**
:   Enable ZX Next extra ASM opcodes!

**--version**
:   Show program's version number and exit.

# BUGS

The upstream BTS can be found at https://github.com/boriel-basic/zxbasic/issues.

# SEE ALSO

**zxbc**(1), **zxbpp**(1)

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
