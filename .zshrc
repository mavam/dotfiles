##
##  Environment
##

umask 022

# OS and hostname
(( ${+OS} ))        || export OS="${OSTYPE%%[0-9.]*}"
(( ${+OSVERSION} )) || export OSVERSION="${OSTYPE#$OS}"
(( ${+OSMAJOR} ))   || export OSMAJOR="${OSVERSION%%.*}"
(( ${+HOSTNAME} ))   || export HOSTNAME=$(uname -n)

# Prefixed portage
if [[ -d ~/gentoo ]]; then
    export EPREFIX=~/gentoo
fi

# Avoid duplicates in $PATH.
typeset -U path

# Respect gentoo and prefix environment.
if [[ -e /etc/profile.env ]]; then 
    source /etc/profile.env
fi
if [[ -n ${EPREFIX} ]]; then
    source ${EPREFIX}/etc/profile.env
    path=( $path $EPREFIX/usr/bin $EPREFIX/bin )
fi

# User path
[[ -d ~/bin ]] && path=( ~/bin $path )

# System $PATH
path=( $path /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin)

# Function path
fpath=(~/.zsh/completions $fpath)


##
##  Resource files
##

# Source general files.
for i in ~/.zsh/rc/*; do
	source $i
done

# Source os specific files.
case ${OS} in
    [Dd]arwin)
    source ~/.zsh/os/macos
esac

# Source host specific files.
[[ -f ~/.zsh/host/$(hostname -s) ]] && source ~/.zsh/host/$(hostname -s)

# Source user specific files.
[[ -f ~/.zsh/user/$(whoami) ]] && source ~/.zsh/user/$(whoami)
