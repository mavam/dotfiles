<p align="center">
  <img width="600" alt="zsh" src="https://user-images.githubusercontent.com/53797/46028848-ee273b80-c0f1-11e8-9e32-a750cd84692b.png">
</p>

Proper dotfiles are the very heart of an efficient working environment.

This repository ships a set of configuration files for modern command line
tools, such as [tmux][tmux], [vim][vim], and [zsh][zsh]. Additionally, it
provides a portable script for managing dotfiles and quickly getting up and
runninng on a new machine.

Usage
=====

Synopsis
--------

These are the quick start instructions to get up and running:

    git clone git@github.com:mavam/dotfiles.git ~/.dotfiles
    cd .dotfiles
    ./bootstrap dotfiles

Make zsh your login shell, install Vim plugins and
[vim-anywhere](https://github.com/cknadler/vim-anywhere), and setup tmux
plugins:

    ./bootstrap zsh vim tmux

On a Mac, you may also consider improving the system experience and installing
[Homebrew][homebrew]:

    ./bootstrap system homebrew

I use [iTerm2](https://iterm2.com) as terminal emulator. Add the light and dark
[gruvbox](https://github.com/morhetz/gruvbox-contrib) by loading [my
settings](iterm2/.iterm2/com.googlecode.iterm2.plist) via *Settings* ->
*General* -> *Browse*. This requires the
[Meslo](https://github.com/andreberg/Meslo-Font) from [Nerd
Fonts](https://github.com/ryanoasis/nerd-fonts) to be installed, which is
readily available [via
Homebrew](https://github.com/ryanoasis/nerd-fonts#option-4-homebrew-fonts).

Local Setup
-----------

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
getting up and running on a new machine. Passing `-h` shows the available
aspects available for configuration:

1. `system`: adjust system defaults for productivity
1. `homebrew`:setup [Homebrew][homebrew] and install bundled packages
1. `dotfiles`: setup dotfiles via `./dots install -a`
1. `postfix`: setup [postfix][postfix] as GMail relay
1. `tmux`: install [tmux][tmux] plugins
1. `vim`: install [vim][vim] plugins
1. `zsh`: setup [zsh][zsh] as login shell

Invoking

    ./bootstrap

without any arguments sets up all aspects in the above order. On macOS, (1)
includes:

1. Adjust various default settings, e.g.:
   - Improve security and privacy settings
   - Disable boot sound
   - Reduce UI effects for improved speed
   - Make the keyboard faster
2. Perform a software update
3. Install XCode

Extras
======

Browser
-------

My browser is Safari, which I beef up with the following enhancements:

- [sVim](https://github.com/flipxfx/sVim) ([example config][svim-config])
- [Adguard](https://adguard.com/en/article/adblock-adguard-safari.html)
- [Disconnect](https://disconnect.me)

Browse through this [curated list of extensions][safari-extensions] for further
inspiration.

[homebrew]: https://brew.sh
[postfix]: http://www.postfix.org
[tmux]: https://github.com/tmux/tmux
[vim]: http://www.vim.org
[zsh]: http://www.zsh.org
[svim-config]: https://gist.github.com/nikitavoloboev/c26e6a05e4e426e0542e55b7513b581c
[safari-extensions]: https://github.com/learn-anything/safari-extensions
