 # =============================================================================
#                          Pre-Plugin Configuration
# =============================================================================

# Automagically quote URLs. This obviates the need to quote them manually when
# pasting or typing URLs.
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# =============================================================================
#                                   Plugins
# =============================================================================

# powerlevel9k prompt theme
DEFAULT_USER=$USER
POWERLEVEL9K_MODE='nerdfont-complete'
#POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
#POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
POWERLEVEL9K_DIR_PATH_SEPARATOR="%F{cyan}/%F{blue}"
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=''
POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=''
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{blue}\u256D\u2500%f"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{blue}\u2570\uf460%f "
POWERLEVEL9K_STATUS_OK=false
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(root_indicator dir_joined
                                   dir_writable_joined vcs virtualenv)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time
                                    background_jobs_joined time_joined
                                    user_joined)
POWERLEVEL9K_VCS_CLEAN_BACKGROUND="clear"
POWERLEVEL9K_VCS_CLEAN_FOREGROUND="green"
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND="clear"
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND="yellow"
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND="clear"
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND="yellow"
POWERLEVEL9K_DIR_HOME_BACKGROUND="clear"
POWERLEVEL9K_DIR_HOME_FOREGROUND="blue"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="clear"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="blue"
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_BACKGROUND="clear"
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND="red"
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND="clear"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="cyan"
POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND="clear"
POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND="red"
POWERLEVEL9K_STATUS_OK_BACKGROUND="clear"
POWERLEVEL9K_STATUS_OK_FOREGROUND="green"
POWERLEVEL9K_STATUS_ERROR_BACKGROUND="clear"
POWERLEVEL9K_STATUS_ERROR_FOREGROUND="red"
#POWERLEVEL9K_TIME_FORMAT="%D{\uf073 %b %d \uf017 %H:%M}" #  Jun 15  09:32
POWERLEVEL9K_TIME_FOREGROUND="blue"
POWERLEVEL9K_TIME_BACKGROUND="clear"
POWERLEVEL9K_TIME_FOREGROUND="blue"
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='clear'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='magenta'
POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND='clear'
POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND='magenta'
POWERLEVEL9K_USER_DEFAULT_BACKGROUND='clear'
POWERLEVEL9K_USER_DEFAULT_FOREGROUND='cyan'
POWERLEVEL9K_USER_ROOT_BACKGROUND='clear'
POWERLEVEL9K_USER_ROOT_FOREGROUND='red'
POWERLEVEL9K_USER_ICON="\uf415" # 
POWERLEVEL9K_ROOT_ICON="\u26a1" # ⚡
POWERLEVEL9K_HOST_LOCAL_BACKGROUND='clear'
POWERLEVEL9K_HOST_LOCAL_FOREGROUND='cyan'
POWERLEVEL9K_HOST_REMOTE_BACKGROUND='clear'
POWERLEVEL9K_HOST_REMOTE_FOREGROUND='magenta'
POWERLEVEL9K_HOST_ICON="\uF109 " # 
POWERLEVEL9K_SSH_ICON="\uF489 "  # 
POWERLEVEL9K_OS_ICON_BACKGROUND="clear"
POWERLEVEL9K_OS_ICON_FOREGROUND="grey"

# zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'fg=white,bold,bg=red')
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]='fg=blue'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[function]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=yellow,bold'

if [[ ! -d "${ZPLUG_HOME}" ]]; then
  if [[ ! -d ~/.zplug ]]; then
    git clone https://github.com/zplug/zplug ~/.zplug
  fi
  export ZPLUG_HOME=~/.zplug
fi
source "${ZPLUG_HOME}/init.zsh"

zplug 'plugins/colored-man-pages', from:oh-my-zsh
zplug 'plugins/git', from:oh-my-zsh, if:'which git'
zplug 'plugins/nmap', from:oh-my-zsh, if:'which nmap'
zplug 'plugins/tmux', from:oh-my-zsh, if:'which tmux'
zplug 'bhilburn/powerlevel9k', use:powerlevel9k.zsh-theme
zplug "junegunn/fzf-bin", as:command, from:gh-r, rename-to:"fzf", frozen:1
zplug "junegunn/fzf", use:"shell/key-bindings.zsh"
zplug "lib/completion", from:oh-my-zsh

#zplug 'seebi/dircolors-solarized', ignore:"*", as:plugin
zplug 'zsh-users/zsh-autosuggestions'
zplug 'zsh-users/zsh-completions', defer:2
zplug 'zsh-users/zsh-history-substring-search'
zplug 'zsh-users/zsh-syntax-highlighting', defer:3
zplug 'superbrothers/zsh-kubectl-prompt'

if ! zplug check; then
  zplug install
fi

zplug load

if zplug check 'zsh-users/zsh-autosuggestions'; then
  # Enable asynchronous fetching of suggestions.
  ZSH_AUTOSUGGEST_USE_ASYNC=1
  # For some reason, the offered completion winds up having the same color as
  # the terminal background color (when using a dark profile). Therefore, we
  # switch to gray.
  # See https://github.com/zsh-users/zsh-autosuggestions/issues/182.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'
fi

# we do not use the `expand-word' widget and only expand a few whitelisted
# aliases.
# See https://github.com/robbyrussell/oh-my-zsh/issues/6123 for discussion.

#zle -N globalias
#bindkey -M emacs ' ' globalias
#bindkey -M viins ' ' globalias
bindkey -M isearch ' ' magic-space # normal space during searches


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
setopt autocd                   # Allow changing directories without `cd`
setopt append_history           # Do not overwrite history
setopt extended_history         # Also record time and duration of commands.
setopt share_history            # Share history between multiple shells
setopt hist_expire_dups_first   # Clear duplicates when trimming internal hist.
setopt hist_find_no_dups        # Do not display duplicates during searches.
setopt hist_ignore_dups         # Ignore consecutive duplicates.
setopt hist_ignore_all_dups     # Remember only one unique copy of the command.
setopt hist_reduce_blanks       # Remove superfluous blanks.
setopt hist_save_no_dups        # Omit older commands in favor of newer ones.

# Changing directories
setopt pushd_ignore_dups        # Do not push copies of the same dir on stack.
setopt pushd_minus              # Reference stack entries with '-'.

setopt extended_glob

# =============================================================================
#                                   Aliases
# =============================================================================

#Kubernetes alias
alias k="kubectl"

# Swift editing and file display.
alias e="$EDITOR"
alias v="$VISUAL"

# Directory coloring
if which gls > /dev/null 2>&1; then
  # Prefer GNU version, since it respects dircolors.
  alias ls='gls --group-directories-first --color=auto'
elif [[ $OSTYPE = (darwin|freebsd)* ]]; then
  export CLICOLOR="YES" # Equivalent to passing -G to ls.
  export LSCOLORS="exgxdHdHcxaHaHhBhDeaec"
else
  alias ls='ls --group-directories-first --color=auto'
fi

# Directory management
alias la='ls -a'
alias ll='ls -l'
alias lal='ls -al'
alias dirs='dirs -v'
push() { pushd $1 > /dev/null 2>&1; dirs -v; }
pop() { popd > /dev/null 2>&1; dirs -v }

# Generic command adaptations.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# OS-specific aliases
if [[ $OSTYPE = darwin* ]]; then
  # Lock screen (e.g., when leaving computer).
  alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
  # Hide/show all desktop icons (useful when presenting)
  alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false \
    && killall Finder"
  alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true \
    && killall Finder"
  # Combine PDFs on the command line.
  pdfcat() {
    if [[ $# -lt 2 ]]; then
      echo "usage: $0 merged.pdf input0.pdf [input1.pdf ...]" > /dev/stderr
      return 1
    fi
    local output="$1"
    shift
    # Try pdfunite first (from Homebrew package poppler), because it's much
    # faster and doesn't perform stupid page rotations.
    if which pdfunite > /dev/null 2>&1; then
      pdfunite "$@" "$output"
    else
      local join='/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py'
      "$join" -o "$output" "$@" && open "$output"
    fi
  }
fi

# =============================================================================
#                                Key Bindings
# =============================================================================

bindkey -e

# Grep anywhere with ^G
bindkey -s '^G' ' | grep '
# Git Commit ^M
bindkey -s '^gm' ' git commit -m \"'


# Common CTRL bindings.
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^f' forward-word
bindkey '^b' backward-word
bindkey '^k' kill-line
bindkey '^d' delete-char

# More convenient acceptance of suggested command line.
if zplug check 'zsh-users/zsh-autosuggestions'; then
  bindkey '^ ' autosuggest-execute
fi

# History
if zplug check 'zsh-users/zsh-history-substring-search'; then
  zmodload zsh/terminfo
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down
  bindkey '^p' history-substring-search-up
  bindkey '^n' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi

# Do not require a space when attempting to tab-complete.
bindkey '^i' expand-or-complete-prefix

# FZF
if zplug check 'junegunn/fzf'; then
  export FZF_DEFAULT_OPTS='--height 30%
      --color fg:223,bg:235,hl:208,fg+:229,bg+:237,hl+:167,border:237
      --color info:246,prompt:214,pointer:214,marker:142,spinner:246,header:214'
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

# When doing `cd ../<TAB>`, don't offer the current directory as an option.
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Show a menu (with arrow keys) to select the process to kill.
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*'   force-list always

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

# Changes an iTerm profile by sending a proprietary escape code that iTerm
# intercepts. This function additionally updates ITERM_PROFILE environment
# variable.
iterm-profile() {
  echo -ne "\033]50;SetProfile=$1\a"
  export ITERM_PROFILE="$1"
}

# Convenience function to update system applications and user packages.
update() {
  # sudoe once
  if ! sudo -n true 2> /dev/null; then
    sudo -v
    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" || exit
    done 2>/dev/null &
  fi
  # System
  sudo softwareupdate -i -a
  # Homebrew
  brew upgrade
  brew cleanup
  # Ruby
  gem update --system
  gem update
  gem cleanup
  # npm
  npm install npm -g
  npm update -g
  # Shell plugin management
  zplug update
  .tmux/plugins/tpm/bin/update_plugins all
  vim +PlugUpgrade +PlugUpdate +PlugCLean! +qa
}

# =============================================================================
#                                   Startup
# =============================================================================

# Load SSH and GPG agents via keychain.
setup_agents() {
  if [[ $UID -eq 0 ]]; then
    return
  fi
  local -a ssh_keys gpg_keys
  ssh_keys=(~/.ssh/**/*pub(.N:r))
  gpg_keys=$(gpg -K --with-colons 2>/dev/null \
               | awk -F : '$1 == "sec" { print $5 }')
  if which keychain > /dev/null 2>&1; then
    if (( $#ssh_keys > 0 )) || (( $#gpg_keys > 0 )); then
      eval $(keychain -q --nogui --eval --host fix \
        --agents ssh,gpg $ssh_keys ${(f)gpg_keys})
    fi
  fi
}
setup_agents
unfunction setup_agents

# Source local customizations.
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

function ssl-check() {
    f=~/.localhost_ssl;
    ssl_crt=$f/server.crt
    ssl_key=$f/server.key
    b=$(tput bold)
    c=$(tput sgr0)

    local_ip=$(ipconfig getifaddr $(route get default | grep interface | awk '{print $2}'))
    # local_ip=999.999.999 # (uncomment for testing)

    domains=(
        "localhost"
        "$local_ip"
    )

    if [[ ! -f $ssl_crt ]]; then
        echo -e "\n🛑  ${b}Couldn't find a Slate SSL certificate:${c}"
        make_key=true
    elif [[ ! $(openssl x509 -noout -text -in $ssl_crt | grep $local_ip) ]]; then
        echo -e "\n🛑  ${b}Your IP Address has changed:${c}"
        make_key=true
    else
        echo -e "\n✅  ${b}Your IP address is still the same.${c}"
    fi

    if [[ $make_key == true ]]; then
        echo -e "Generating a new Slate SSL certificate...\n"
        count=$(( ${#domains[@]} - 1))
        mkcert ${domains[@]}

        # Create Slate's default certificate directory, if it doesn't exist
        test ! -d $f && mkdir $f

        # It appears mkcert bases its filenames off the number of domains passed after the first one.
        # This script predicts that filename, so it can copy it to Slate's default location.
        if [[ $count = 0 ]]; then
            mv ./localhost.pem $ssl_crt
            mv ./localhost-key.pem $ssl_key
        else
            mv ./localhost+$count.pem $ssl_crt
            mv ./localhost+$count-key.pem $ssl_key
        fi
    fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
