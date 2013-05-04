#
# .zshrc
#

# Source OS-specific customizations.
[[ -f ~/.zsh/os/$OS ]] && source ~/.zsh/os/$OS

# Source user-specific customizations.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Source general files.
for i (~/.zsh/rc/*(.)) { source $i }
