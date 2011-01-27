#
# .zshrc
#

# Source general files.
for i (~/.zsh/rc/*) { source $i }

# Source OS specific resource files.
[[ -f ~/.zsh/os/$OS ]] && source ~/.zsh/os/$OS

# Source host specific files.
[[ -f ~/.zsh/host/$HOST ]] && source ~/.zsh/host/$HOST

# Source user specific files.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
