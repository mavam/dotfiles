# ---------------------------------------------------
#                      bashrc
# ---------------------------------------------------


# --------------- general --------------- #
umask 022


# --------------- export --------------- #
export HOSTNAME=$(uname -n)

# set the system $PATH
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

# user path
if [[ -d ~/bin ]] ; then
	export PATH=~/bin:$PATH
fi

# editor
if [[ -x $(which vim) ]]; then
	export EDITOR="vim"
	export VISUAL="${EDITOR}"
else
	if [[ -x $(which vi) ]]; then
		export EDITOR="vi"
	fi
fi

# pager
export PAGER="less -S"

# cvs
export CVS_RSH="ssh"
export CVSEDITOR="vim"

# rsync
export RSYNC_RSH="ssh"


# --------------- aliases --------------- #
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'

# colorized ls (os specific)
case ${OS} in
	freebsd|darwin)
	alias ls='ls -G'
	;;
	linux-gnu)
	alias ls='ls --color=auto'
	;;
esac

alias la='ls -al'
alias ll='ls -l'
alias lh='ls -l'

alias dz='ls -al | sort -nr +4 | tail -10'

alias v="vim"
alias vi="vim"
