# Environment variables
# ---------------------------------------------------------------------
set -g fish_greeting

# OS-specific paths
switch (uname)
  case Darwin
    fish_add_path -g /opt/homebrew/bin    # Homebrew
    fish_add_path -g /usr/X11R6/bin       # Apple's X11
    fish_add_path -g /Library/TeX/texbin  # MacTeX
end

# Rust
fish_add_path -g $HOME/.cargo/bin

# Go
set -x GOPATH $HOME/.go
fish_add_path -g $GOPATH/bin

# Editor
if command -sq nvim
  set -x VISUAL nvim
  abbr -g vim nvim
  abbr -g vi nvim
  abbr -g n nvim
else if command -sq vim
  set -x VISUAL vim
  abbr -g vi vim
else
  set -x VISUAL vi
end
set -x EDITOR $VISUAL

# Pager
if command -sq bat
  set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

# Homebrew
if command -sq brew
  set -x HOMEBREW_NO_ANALYTICS 1
  set -x HOMEBREW_AUTO_UPDATE_SECS 604800 # 1 week
  # Latest LLVM compiler
  set -l llvm_prefix (brew --prefix llvm)
  if test -d $llvm_prefix
    set -x CC $llvm_prefix/bin/clang
    set -x CXX $llvm_prefix/bin/clang++
    set -px CPPFLAGS -isystem $llvm_prefix/include
    set -px CXXFLAGS -isystem $llvm_prefix/include/c++/v1
    set -px LDFLAGS -Wl,-rpath,$llvm_prefix
    fish_add_path -g $llvm_prefix
  end
end

# CMake
set -x CMAKE_GENERATOR Ninja
set -x CMAKE_C_COMPILER_LAUNCHER ccache
set -x CMAKE_CXX_COMPILER_LAUNCHER ccache

# Docker
set -x DOCKER_BUILDKIT 1

# FZF tuning
#
# Light mode still to be integrated:
#--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
#--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
#--color=marker:#dc8a78,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39"
set -x FZF_DEFAULT_OPTS \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --bind=ctrl-k:up,ctrl-j:down,ctrl-h:page-up,ctrl-l:page-down \
  --bind=ctrl-p:half-page-up,ctrl-n:half-page-down \
  --bind=ctrl-e:preview-down,ctrl-y:preview-up \
  --bind=ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down \
  --bind=ctrl-b:preview-page-up,ctrl-f:preview-page-down \
  --preview-window=top

# Interactive shells
# ---------------------------------------------------------------------
if status is-interactive
  # Vi bindings.
  fish_vi_key_bindings
  # CTRL+e for "e"xecute auto-suggestion.
  bind -M insert \ce accept-autosuggestion execute
  # CTRL+o for "o"pen .
  bind \co _fzf_search_directory
  bind -M insert \co _fzf_search_directory
  # CTRL+g for "g"it log.
  bind \cg _fzf_search_git_log
  bind -M insert \cg _fzf_search_git_log
  # CTRL+b for "b"rocess, brother.
  bind -M insert \cb _fzf_search_processes
  # CTRL+n/p for quick history traversal
  bind \cn history-prefix-search-forward
  bind -M insert \cn history-prefix-search-forward
  bind \cp history-prefix-search-backward
  bind -M insert \cp history-prefix-search-backward

  # Setup prompt
  starship init fish | source
  enable_transience

  # Launch gpg-agent for use by SSH.
  set -x GPG_TTY (tty)
  set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent

  # Kanagawa color scheme: https://github.com/rebelot/kanagawa.nvim/
  set -l foreground DCD7BA
  set -l selection 2D4F67
  set -l comment 727169
  set -l red C34043
  set -l orange FF9E64
  set -l yellow C0A36E
  set -l green 76946A
  set -l purple 957FB8
  set -l cyan 7AA89F
  set -l pink D27E99
  # Syntax Highlighting Colors
  set -g fish_color_normal $foreground
  set -g fish_color_command $cyan
  set -g fish_color_keyword $pink
  set -g fish_color_quote $yellow
  set -g fish_color_redirection $foreground
  set -g fish_color_end $orange
  set -g fish_color_error $red
  set -g fish_color_param $purple
  set -g fish_color_comment $comment
  set -g fish_color_selection --background=$selection
  set -g fish_color_search_match --background=$selection
  set -g fish_color_operator $green
  set -g fish_color_escape $pink
  set -g fish_color_autosuggestion $comment
  # Completion Pager Colors
  set -g fish_pager_color_progress $comment
  set -g fish_pager_color_prefix $cyan
  set -g fish_pager_color_completion $foreground
  set -g fish_pager_color_description $comment

  # Simplify SSH: https://sw.kovidgoyal.net/kitty/kittens/ssh/
  abbr -g s 'kitty +kitten ssh'

  # Abbreviations: git
  abbr -g g 'git'
  abbr -g ga 'git add'
  abbr -g gaa 'git add --all'
  abbr -g gb 'git branch'
  abbr -g gbd 'git branch -D'
  abbr -g gbl 'git blame'
  abbr -g gc 'git commit -v'
  abbr -g gc! 'git commit -v --amend'
  abbr -g gcn! 'git commit -v --amend --no-edit'
  abbr -g gca 'git commit -a -v'
  abbr -g gca! 'git commit -a -v --amend'
  abbr -g gcan! 'git commit -a -v --no-edit --amend'
  abbr -g gcans! 'git commit -a -v -s --no-edit --amend'
  abbr -g gcl 'git clone --recursive'
  abbr -g gcf 'git config --list'
  abbr -g gclean 'git clean -fd'
  abbr -g gco 'git checkout'
  abbr -g gcob 'git checkout -b'
  abbr -g gcom 'git checkout master'
  abbr -g gcot 'git checkout topic/'
  abbr -g gcp 'git cherry-pick'
  abbr -g gcpa 'git cherry-pick --abort'
  abbr -g gcpc 'git cherry-pick --continue'
  abbr -g gd 'git diff'
  abbr -g gdc 'git diff --cached'
  abbr -g gf 'git fetch'
  abbr -g gfa 'git fetch --all --prune'
  abbr -g gfo 'git fetch origin'
  abbr -g gl 'git log'
  abbr -g gla 'git log --all --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"'
  abbr -g glg 'git log --graph'
  abbr -g glp 'git log --patch'
  abbr -g gm 'git merge'
  abbr -g gp 'git push'
  abbr -g gpu 'git push --set-upstream origin (git symbolic-ref HEAD | sed "s/refs\/heads\///")'
  abbr -g gpf 'git push --force'
  abbr -g gpt 'git push --tags'
  abbr -g gptf 'git push --tags --force'
  abbr -g gpoat 'git push origin --all && git push origin --tags'
  abbr -g gpoatf 'git push origin --all -f && git push origin --tags -f'
  abbr -g gpl 'git pull'
  abbr -g gplo 'git pull origin'
  abbr -g gplom 'git pull origin master'
  abbr -g gplu 'git pull upstream'
  abbr -g gplum 'git pull upstream master'
  abbr -g gr 'git remote -v'
  abbr -g gra 'git remote add'
  abbr -g grau 'git remote add upstream'
  abbr -g grrm 'git remote remove'
  abbr -g grmv 'git remote rename'
  abbr -g grset 'git remote set-url'
  abbr -g grb 'git rebase'
  abbr -g grbpr 'git rebase --interactive --rebase-merges $(git merge-base origin/master HEAD)'
  abbr -g grba 'git rebase --abort'
  abbr -g grbc 'git rebase --continue'
  abbr -g gr 'git reset'
  abbr -g gru 'git reset @{u}'
  abbr -g grh 'git reset --hard'
  abbr -g grhu 'git reset --hard @{u}'
  abbr -g grhh 'git reset --hard HEAD'
  abbr -g gst 'git status'
  abbr -g gsts 'git status -s'
  abbr -g gsh 'git stash push'
  abbr -g gsha 'git stash apply'
  abbr -g gshd 'git stash drop'
  abbr -g gshp 'git stash pop'
  abbr -g gsu 'git submodule update'
  abbr -g gts 'git tag -s'

  # Let vim fugitive creep into shell workflow.
  function G
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1
      nvim +G +only
    else
      echo not inside a git work tree
    end
  end

  # macOS convenience tools.
  switch (uname)
    case Darwin
      alias hide-desktop 'defaults write com.apple.finder CreateDesktop -bool false \
        && killall Finder'
      alias show-desktop 'defaults write com.apple.finder CreateDesktop -bool true \
        && killall Finder'
  end
end
