# =============================================================================
#                                   Plugins
# =============================================================================

# powerlevel9k prompt theme
POWERLEVEL9K_MODE='nerdfont-complete'
#POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
#POWERLEVEL9K_SHORTEN_DELIMITER=""
#POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="%{%F{blue}%}❯ "
POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="%{%F{cyan}%}\uf460%{%F{white}%} "
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(root_indicator dir dir_writable_joined)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time background_jobs
                                    vcs time_joined)
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND="clear"
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND="clear"
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND="yellow"
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND="yellow"
POWERLEVEL9K_DIR_HOME_BACKGROUND="clear"
POWERLEVEL9K_DIR_HOME_FOREGROUND="blue"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="clear"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="blue"
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_BACKGROUND="clear"
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND="red"
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND="clear"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="white"
POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND="red"
POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND="white"
POWERLEVEL9K_STATUS_OK_BACKGROUND="clear"
POWERLEVEL9K_STATUS_OK_FOREGROUND="green"
POWERLEVEL9K_STATUS_ERROR_BACKGROUND="clear"
POWERLEVEL9K_STATUS_ERROR_FOREGROUND="red"
POWERLEVEL9K_TIME_BACKGROUND="clear"
POWERLEVEL9K_TIME_FOREGROUND="white"
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='clear'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='cyan'

if [[ ! -d "${ZPLUG_HOME}" ]]; then
  git clone https://github.com/zplug/zplug "${ZPLUG_HOME}"
fi

source "${ZPLUG_HOME}/init.zsh"

zplug 'plugins/bundler', from:oh-my-zsh
zplug 'plugins/colored-man-pages', from:oh-my-zsh
zplug 'plugins/extract', from:oh-my-zsh
zplug 'plugins/git', from:oh-my-zsh
zplug 'plugins/globalias', from:oh-my-zsh
zplug 'plugins/httpie', from:oh-my-zsh
zplug 'plugins/nanoc', from:oh-my-zsh
zplug 'plugins/nmap', from:oh-my-zsh
zplug 'plugins/tmux', from:oh-my-zsh
zplug 'plugins/vi-mode', from:oh-my-zsh

#zplug 'b4b4r07/enhancd', use:init.sh
zplug 'b4b4r07/zsh-vimode-visual', defer:3
zplug 'bhilburn/powerlevel9k', use:powerlevel9k.zsh-theme
zplug 'seebi/dircolors-solarized', ignore:"*", as:plugin
zplug 'zsh-users/zsh-autosuggestions', at:develop
zplug 'zsh-users/zsh-completions', defer:2
zplug 'zsh-users/zsh-history-substring-search'
zplug 'zsh-users/zsh-syntax-highlighting', defer:2

if ! zplug check; then
  zplug install
fi

zplug load

# zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=yellow,bold'
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'fg=white,bold,bg=red')

# dircolors-solarized
if zplug check 'seebi/dircolors-solarized'; then
  if which gdircolors > /dev/null 2>&1; then
    alias dircolors='gdircolors'
  fi
  if which dircolors > /dev/null 2>&1; then
    scheme='dircolors.256dark'
    eval $(dircolors $ZPLUG_HOME/repos/seebi/dircolors-solarized/$scheme)
  fi
fi

# =============================================================================
#                                   Options
# =============================================================================

# Watching other users
WATCHFMT='%n %a %l from %m at %t.'
watch=(notme)         # Report login/logout events for everybody except ourself.
LOGCHECK=60           # Time (seconds) between checks for login/logout activity.
REPORTTIME=5          # Display usage statistics for commands running > 5 sec.
WORDCHARS="\'*?_-.[]~=/&;!#$%^(){}<>\'"

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt append_history           # Don't overwrite history
setopt extended_history         # Also record time and duration of commands.
setopt share_history            # Share history between multiple shells
setopt hist_expire_dups_first   # Clear duplicates when trimming internal hist.
setopt hist_find_no_dups        # Don't display duplicates during searches.
setopt hist_ignore_dups         # Ignore consecutive duplicates.
setopt hist_ignore_all_dups     # Remember only one unique copy of the command.
setopt hist_reduce_blanks       # Remove superfluous blanks.
setopt hist_save_no_dups        # Omit older commands in favor of newer ones.

# Changing directories
setopt pushd_ignore_dups        # Don't push copies of the same dir on stack.
setopt pushd_minus              # Reference stack entries with '-'.

setopt extended_glob

# =============================================================================
#                                   Aliases
# =============================================================================

# In the definitions below, you will see use of function definitions instead of
# aliases for some cases. We use this method to avoid expansion of the alias in
# combination with the globalias plugin.

# Directory coloring
if which gls > /dev/null 2>&1; then
  # Prefer GNU version, since it respects dircolors.
  ls() { gls --color=auto $@ }
elif [[ $OSTYPE = (darwin|freebsd)* ]]; then
  export CLICOLORS="YES" # Equivalent to passing -G to ls.
  export LSCOLORS="GxFxFxdxCxDxDxhbadExEx"
fi

# Directory management
alias la='ls -a'
alias ll='ls -l'
alias lal='ls -l'
alias d='dirs -v'
alias 1='pu'
alias 2='pu -2'
alias 3='pu -3'
alias 4='pu -4'
alias 5='pu -5'
alias 6='pu -6'
alias 7='pu -7'
alias 8='pu -8'
alias 9='pu -9'
pu() { pushd $1 > /dev/null 2>&1; dirs -v; }
po() { popd > /dev/null 2>&1; dirs -v }

# Generic command adaptations.
grep() { $(whence -p grep) --colour=auto $@ }
egrep() { $(whence -p egrep) --colour=auto $@ }

# =============================================================================
#                                Key Bindings
# =============================================================================

# Common CTRL bindings.
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^f' forward-word
bindkey '^b' backward-word
bindkey '^k' kill-line
bindkey '^d' delete-char
bindkey '^y' accept-and-hold
bindkey '^w' backward-kill-word
bindkey '^u' backward-kill-line

# History
if zplug check 'zsh-users/zsh-history-substring-search'; then
  zmodload zsh/terminfo
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down
  bindkey -M emacs '^P' history-substring-search-up
  bindkey -M emacs '^N' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi

# =============================================================================
#                                 Completions
# =============================================================================

# case-insensitive (all), partial-word and then substring completion
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# =============================================================================
#                                    Other
# =============================================================================

# Utility that prints out lines that are common among $# files.
intersect() {
  local sort='sort -S 1G'
  case $# in
    (0) true;;
    (2) $sort -u "$1"; $sort -u "$2";;
    (*) $sort -u "$1"; shift; intersection "$@";;
  esac | $sort | uniq -d
}

# =============================================================================
#                                   Startup
# =============================================================================

# Load SSH and GPG agents
setup_agents() {
  local ssh_keys=(~/.ssh/**/*pub(:r))
  local gpg_keys=${${${(M)${(f)"$(gpg --list-secret-keys \
    --list-options no-show-photos 2>/dev/null)"}:%sec*}#sec */}%% *}
  if [[ -n "$ssh_keys" ]] || [[ -n "$gpg_keys" ]]; then
    eval $(keychain -q --nogui --eval --host fix \
           --agents ssh,gpg $ssh_keys $gpg_keys)
  fi
}
setup_agents

# Source local customizations.
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

# vim: ft=zsh
