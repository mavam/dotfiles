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

if [[ -f $HOME/.zpath ]]; then
    source $HOME/.zpath
fi

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

# Beautify man pages.
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Setup Ruby gem environment.
if which gem &> /dev/null; then
    local gempath=$(gem env gempath)
    (( $? == 0 )) && export GEM_PATH=~/.gem:$gempath
    export GEM_HOME=~/.gem
    path=( $GEM_HOME/bin $path )
fi

# Source OS specific environment
if [[ -f $HOME/.zshenv.${OS} ]]; then
    source $HOME/.zshenv.${OS}
fi

# Source local environment
if [[ -f $HOME/.zshenv.local ]]; then
    source $HOME/.zshenv.local
fi

# vim: ft=zsh
