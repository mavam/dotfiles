# ---------------------------------------------------
#                      bashrc
# ---------------------------------------------------

umask 022

export HOSTNAME=$(uname -n)
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
[[ -d ~/bin ]] && export PATH=~/bin:$PATH

export PAGER="less -S"
export CVS_RSH="ssh"
export CVSEDITOR="vim"
export RSYNC_RSH="ssh"

if [[ -x $(which vim) ]]; then
	export EDITOR="vim"
	export VISUAL="${EDITOR}"
else
	if [[ -x $(which vi) ]]; then
		export EDITOR="vi"
	fi
fi

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

alias v="vim"
alias vi="vim"
