#
# Unless -f is specified, .zshenv is sourced on all shell invocations.
# Consequently, there should be only critical commands environment in this file.
#

umask 022

# OS and hostname
(( ${+OS} ))        || export OS="${OSTYPE%%[0-9.]*}"
(( ${+OSVERSION} )) || export OSVERSION="${OSTYPE#$OS}"
(( ${+OSMAJOR} ))   || export OSMAJOR="${OSVERSION%%.*}"
(( ${+HOSTNAME} ))  || export HOSTNAME=$(uname -n)

[[ -f ~/.zpath ]] && source ~/.zpath

# Setup locale.
if which locale &> /dev/null; then
    if [[ $(locale -a | grep '^en_US.utf8$') == "en_US.utf8" ]] ; then
        export LANG=en_US.utf8
    elif [[ $(locale -a | grep '^en_US.UTF-8$') == "en_US.UTF-8" ]] ; then
        export LANG=en_US.UTF-8
    elif [[ $(locale -a | grep '^en_US.iso88591$') == "en_US.iso88591" ]] ; then
        export LANG=en_US.iso88591
    elif [[ $(locale -a | grep '^en_US$') == "en_US" ]] ; then
        export LANG=en_US
    else 
        export LANG=C
    fi
fi

# Editor
if which vim &> /dev/null; then
    export EDITOR="vim"
    export VIMRELEASE="$(print ${${$(vim --version)[5]}:gs/.//})"
elif which vi &> /dev/null; then
    export EDITOR="vi"
fi
export VISUAL=$EDITOR

# Pager.
export PAGER="less -S"

# Version control software.
export CVS_RSH="ssh"
export CVSEDITOR="vim"
export RSYNC_RSH="ssh"

# GPG
export GPG_TTY=$TTY

# Beautify man pages.
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Setup RVM environment.
[[ -s ~/.rvm/scripts/rvm ]] && source ~/.rvm/scripts/rvm

# Source OS-specific environment.
[[ -f ~/.zsh/env/$OS ]] && source ~/.zsh/env/$OS

# Source local environment.
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

# vim: ft=zsh
