                           __      __  _____ __
                      ____/ /___  / /_/ __(_) /__  _____
                     / __  / __ \/ __/ /_/ / / _ \/ ___/
                    / /_/ / /_/ / /_/ __/ / /  __(__  )
                    \__,_/\____/\__/_/ /_/_/\___/____/


Proper dotfiles are the very heart of an efficient working environment.

This repository ships a set of configuration files for modern command line
tools, such as [tmux][tmux], [vim][vim], and [zsh][zsh]. Additionally, it
provides a portable script for managing dotfiles and quickly getting up and
runninng on a new machine.

Usage
=====

Begin with cloning this repository somewhere:

    git clone git@github.com:mavam/dotfiles.git ~/.dotfiles
    cd .dotfiles

Dotfile Management
------------------

The POSIX shell script [dots](dots) installs (= symlinks) and removes subsets
of dotfiles according to your needs. For example, install all dotfiles as
follows:

    ./dots install -a

Alternatively, install only dotfiles for vim and zsh:

    ./dots install vim zsh

Similarly, remove all installed dotfiles:

    ./dots uninstall -a

The installer script does not override existing dotfiles unless the command
line includes the `-f` switch. When in doubt what the installation of a subset
of the dotfiles would look like, it is possible to look at the diff first:

    ./dots diff -a

System Bootstrapping
--------------------

In addition to managing dotfiles, the script [bootstrap](bootstrap) facilitates
getting up and running on a new machine:

    ./bootstrap

The script performs the following actions:

1. Perform OS-specific adjustments
2. Install Homebrew plus all [bundled packages](Brewfile)
3. Set [zsh][zsh] as login shell
4. Install [vim][vim] and [tmux][tmux] plugins

On macOS, (1) includes:

1. Adjust various default settings, e.g.:
  - Improve security and privacy settings
  - Disable boot sound
  - Reduce UI effects for improved speed
  - Make the keyboard faster
2. Perform a software update
3. Install XCode

[tmux]: https://github.com/tmux/tmux
[vim]: http://www.vim.org
[zsh]: http://www.zsh.org
