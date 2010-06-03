#
# zshrc 
#

# Load the completion system.
autoload -U compinit
compinit -u

# Source general files.
for i (~/.zsh/rc/*) { source $i }

# Source OS specific resource files.
if [[ -f ~/.zsh/os/${OS} ]]; then
    source ~/.zsh/os/${OS}
fi

# Source host specific files.
if [[ -f ~/.zsh/host/$HOST ]]; then
    source ~/.zsh/host/$HOST
fi

# Source user specific files.
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
