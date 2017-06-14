                           __      __  _____ __
                      ____/ /___  / /_/ __(_) /__  _____
                     / __  / __ \/ __/ /_/ / / _ \/ ___/
                    / /_/ / /_/ / /_/ __/ / /  __(__  )
                    \__,_/\____/\__/_/ /_/_/\___/____/


Proper dotfiles are the very heart of an efficient working environment.

This repository ships a set of configuration files for modern command line
tools, such as [tmux][tmux], [vim][vim], and [zsh][zsh].

Usage
=====

First, clone this repository somewhere:

    git clone git@github.com:mavam/dotfiles.git ~/.dotfiles
    cd .dotfiles

Then, use the POSIX shell script [dots](dots) for installing
(= symlinking) and removing subsets of dotfiles according to your needs. For
example, install all dotfiles as follows:

    ./dots install -a

Alternatively, install only dotfiles for vim and zsh:

    ./dots install vim zsh

Similarly, to removing all symlinked directories:

    ./dots uninstall -a

The installer script does not override existing dotfiles, unless the command
line includes the `-f` switch. When in doubt what the installation of a subset
of the dotfiles would look like, it is possible to look at the diff first:

    ./dots diff -a

[tmux]: https://github.com/tmux/tmux
[vim]: http://www.vim.org
[zsh]: http://www.zsh.org
