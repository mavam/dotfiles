#
# .zshrc
#

# Source general files.
for i (~/.zsh/rc/*(.)) { source $i }

# Source OS specific resource files.
[[ -f ~/.zsh/rc/os/$OS ]] && source ~/.zsh/rc/os/$OS

# Source host specific files.
[[ -f ~/.zsh/rc/host/$HOST ]] && source ~/.zsh/rc/host/$HOST

# Source user specific files.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
