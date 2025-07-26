# NAME

zxbc - Boriel BASIC compiler

# SYNOPSIS

**zxbc** [-h] [-d] [-O OPTIMIZE] [-o OUTPUT_FILE]
     [-T | -t | -A | -E | --parse-only | -f {asm,bin,ir,sna,tap,tzx,z80}]
     [-B] [-a] [-S ORG] [-e STDERR] [--array-base ARRAY_BASE]
     [--string-base STRING_BASE] [-Z] [-H HEAP_SIZE]
     [--heap-address HEAP_ADDRESS] [--debug-memory] [--debug-array]
     [--strict-bool] [--enable-break] [--explicit] [-D DEFINES]
     [-M MEMORY_MAP] [-i] [-I INCLUDE_PATH] [--strict] [--headerless]
     [--version] [--append-binary APPEND_BINARY]
     [--append-headless-binary APPEND_HEADLESS_BINARY] [-N]
     [--arch ARCH] [--expect-warnings EXPECT_WARNINGS]
     [-W DISABLE_WARNING] [+W ENABLE_WARNING] [--hide-warning-codes]
     [-F CONFIG_FILE] [--save-config SAVE_CONFIG]
     [--opt-strategy {size,speed,auto}]
     PROGRAM.bas

# DESCRIPTION

**zxbc** is the main executable. It can act both as a compiler or as a translator:

* When used as a _compiler_ (this is the default behavior) it will convert a `.BAS`
  text file to a binary `.BIN` or `.TZX` file you can later run on your Spectrum
  or in a ZX Spectrum emulator. 
* If invoked as a _translator_ it will convert a `.BAS` file to assembler
  (`.ASM` source file). You can alter edit this assembler text file
  (for example to perform some low-level modifications or just to see
  how the compiler does it work!).

# OPTIONS

The program follows the usual GNU command line syntax, with long options
starting with two dashes ('-'). A summary of options is included below.

**-h, --help**
:   Show help message and exit.

**-d, --debug**
:   Enable verbosity/debugging output. Additional `-d` increase verbosity/debug level.

**-O OPTIMIZE, --optimize OPTIMIZE**
:   Sets optimization level. 0 = None (default level is 2).

**-o OUTPUT\_FILE, --output OUTPUT\_FILE**
:   Sets output file. Default is input filename with `.bin` extension.

**-T, --tzx**
:   Sets output format to `.tzx` (default is `.bin`).

**-t, --tap**
:   Sets output format to `.tap` (default is `.bin`).

**-A, --asm**
:   Sets output format to `.asm`. DEPRECATED. Use `-f`.

**-E, --emit-backend**
:   Emits backend code (IR) instead of ASM or binary.

**--parse-only**
:   Only parses to check for syntax and semantic errors.

**-f {asm,bin,ir,sna,tap,tzx,z80}, --output-format {asm,bin,ir,sna,tap,tzx,z80}**
:   Output format.

**-B, --BASIC**
:   Creates a BASIC loader which loads the rest of the CODE. Requires `-T` ot `-t`.

**-a, --autorun**
:   Sets the program to be run once loaded.

**-S ORG, --org ORG**
:   Start of machine code. By default is 32768 ($8000).

**-e STDERR, --errmsg STDERR**
:   Error messages file (standard error console by default).

**--array-base ARRAY\_BASE**
:   Default lower index for arrays (0 by default).

**--string-base STRING\_BASE**
:   Default lower index for strings (0 by default).

**-Z, --sinclair**
:   Enable by default some more original ZX Spectrum Sinclair BASIC features: `ATTR`, `SCREEN$`, `POINT`.

**-H HEAP_SIZE, --heap-size HEAP\_SIZE**
:   Sets heap size in bytes (default 4768 bytes).

**--heap-address HEAP\_ADDRESS**
:   Sets the heap address.

**--debug-memory**
:   Enables out-of-memory debug.

**--debug-array**
:   Enables array boundary checking.

**--strict-bool**
:   Enforce boolean values to be 0 or 1 (Deprecated).

**--enable-break**
:   Enables program execution `BREAK` detection.

**--explicit**
:   Requires all variables and functions to be declared before used.

**-D DEFINES, --define DEFINES**
:   Defines de given macro. Eg. `-D MYDEBUG` or `-D NAME=Value`

**-M MEMORY\_MAP, --mmap MEMORY\_MAP**
:   Generate label memory map.

**-i, --ignore-case**
:   Ignore case. Makes variable and function names insensitive.

**-I INCLUDE\_PATH, --include-path INCLUDE\_PATH**
:   Add colon separated list of directories to add to include path. e.g. `-I dir1:dir2`

**--strict**
:   Enables strict mode. Force explicit type declaration.

**--headerless**
:   Header-less mode: omit asm prologue and epilogue.

**--version**
:   show program's version number and exit.

**--append-binary APPEND\_BINARY**
:   Appends binary to tape file (only works with -t or -T).

**--append-headless-binary APPEND\_HEADLESS\_BINARY**
:   Appends binary to tape file (only works with -t or -T).

**-N, --zxnext**
:   Enables ZX Next asm extended opcodes.

**--arch ARCH**
:   Target architecture (defaults is 'zx48k'). Available architectures: `zx48k`, `zxnext`.

**--expect-warnings EXPECT\_WARNINGS**
:   Expects N warnings: first N warnings will be silenced.

**-W DISABLE\_WARNING, --disable-warning DISABLE\_WARNING**
:   Disables warning `WXXX` (i.e. `-W100` disables warning with code W100).

**+W ENABL\_WARNING, --enable-warning ENABLE\_WARNING**
:   Enables warning `WXXX` (i.e. `-W100` disables warning with code W100).

**--hide-warning-codes**
:   Hides WXXX codes.

**-F CONFIG\_FILE, --config-file CONFIG\_FILE**
:   Loads config from config file.

**--save-config SAVE\_CONFIG**
:   Save options into a config file.

**--opt-strategy {size,speed,auto}**
:   Optimization strategy (optimize for speed or size). Default: auto.

# BUGS

The upstream BTS can be found at https://github.com/boriel-basic/zxbasic/issues.

# SEE ALSO

**zxbasm**(1), **zxbpp**(1)

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
