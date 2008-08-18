##
##  Environment
##

umask 022

# OS and hostname
(( ${+OS} ))        || export OS="${OSTYPE%%[0-9.]*}"
(( ${+OSVERSION} )) || export OSVERSION="${OSTYPE#$OS}"
(( ${+OSMAJOR} ))   || export OSMAJOR="${OSVERSION%%.*}"
(( ${+HOSTNAME} ))  || export HOSTNAME=$(uname -n)

# Automatically remove duplicates from these arrays.
typeset -U path cdpath fpath manpath

# User path
[[ -d ~/bin ]] && path=( ~/bin $path )

# System $PATH
path=( $path /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin)

# Function path
fpath=(~/.zsh/completions $fpath)

# Load the completion system
autoload -U compinit
compinit -u

##
##  Resource files
##

# Source os specific files.
case ${OS} in
    [Dd]arwin)
    source ~/.zsh/os/macos
esac

# Source general files.
for i in ~/.zsh/rc/*; do
	source $i
done

# At last, source user specific files.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
