# Advent Of Code 2021

This set of solutions tracks the master branch of Zig, *not* 0.8.1.  It may not work with older versions.

## How to build:

The src/ directory contains a main file for each day, containing solutions.  The build command `zig build dayXX [target and mode options] -- [program args]` will build and run the specified day.  You can also use `zig build install_dayXX [target and mode options]` to build the executable for a day and put it into `zig-out/bin` without executing it.  By default this template does not link libc, but you can set `should_link_libc` to `true` in build.zig to change that.

This repo also contains Visual Studio Code project files for debugging.  These are meant to work with the C/C++ plugin.  There is a debug configuration for each day.  By default all days are built in debug mode, but this can be changed by editing `.vscode/tasks.json` if you have a need for speed.

## Setting up ZLS

Zig has a reasonably robust language server, which can provide autocomplete for VSCode and many other editors.  It can help significantly with exploring the std lib and suggesting parameter completions.  To set it up, make sure you have an up-to-date master build of Zig (which you can [download here](https://ziglang.org/download/)), and then run the following commands:

```
git clone --recurse-submodules https://github.com/zigtools/zls
cd zls
zig build -Drelease-fast
zig-out/bin/zls configure
```

The last command will direct you to documentation for connecting it to your preferred editor.  If you are using VSCode, the documentation [can be found here](https://github.com/zigtools/zls/wiki/Installing-for-Visual-Studio-Code).
