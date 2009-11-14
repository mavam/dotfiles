#
# zshrc 
#

# Load the completion system.
autoload -U compinit
compinit -u

# Source general files.
for i (~/.zsh/rc/*) { source $i }

# Source OS specific resource files.
if [[ -f $HOME/.zsh/os/${OS} ]]; then
    source $HOME/.zsh/os/${OS}
fi

# Source user specific files.
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
