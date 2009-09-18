#
# zsh 
#

umask 022

# OS and hostname
(( ${+OS} ))        || export OS="${OSTYPE%%[0-9.]*}"
(( ${+OSVERSION} )) || export OSVERSION="${OSTYPE#$OS}"
(( ${+OSMAJOR} ))   || export OSMAJOR="${OSVERSION%%.*}"
(( ${+HOSTNAME} ))  || export HOSTNAME=$(uname -n)

# Automatically remove duplicates from these arrays.
typeset -U path cdpath fpath manpath

# System $PATH
path=( 
    ~/bin
    $path 
    /usr/local/bin
    /usr/bin
    /bin
    /usr/local/sbin
    /usr/sbin
    /sbin
    /usr/X11R6/bin      # X11
    /usr/ucb            # SunOS
    /usr/sww/bin        # SunOS
)

manpath=(
    $manpath
    ~/man
    /usr/local/man
    /usr/man
)

# Function path
fpath=(~/.zsh/completions $fpath)

# Load the completion system
autoload -U compinit
compinit -u

# Source os specific files.
case ${OS} in
    [Dd]arwin)
    source ~/.zsh/os/macos
esac

# Source general files.
for i (~/.zsh/rc/*) { source $i }

# Source user specific files.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Removes non-existent directories from an array.
clean-path ()
{             
    local element
    local build
    build=()
    # Make sure that this works even with variables containing IFS characters,
    # if you're crazy enough to setopt shwordsplit.
    eval '
    foreach element in "$'"$1"'[@]"; do
        [[ -d "$element" ]] && build=("$build[@]" "$element")
    done
    '"$1"'=( "$build[@]" )
    '
}

# Finally, clean path variables.
clean-path path
clean-path manpath
clean-path fpath
