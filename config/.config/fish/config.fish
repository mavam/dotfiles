# Environment variables
# ---------------------------------------------------------------------
set -g fish_greeting

set -x VISUAL nvim
set -x EDITOR $VISUAL

# Homebrew
if command -q brew
  set -x HOMEBREW_NO_ANALYTICS 1
  set -x HOMEBREW_AUTO_UPDATE_SECS 604800 # 1 week
  # Latest LLVM compiler
  set -l llvm_prefix (brew --prefix llvm)/bin
  set -x CC $llvm_prefix/bin/clang
  set -x CXX $llvm_prefix/bin/clang++
  set -px CPPFLAGS -isystem $llvm_prefix/include
  set -px CXXFLAGS -isystem $llvm_prefix/include/c++/v1
  set -px LDFLAGS -Wl,-rpath,$llvm_prefix
  fish_add_path (brew --prefix)/bin
  fish_add_path $llvm_prefix
end

# Rust
fish_add_path $HOME/.cargo/bin

# Go
set -x GOPATH $HOME/.go
fish_add_path $GOPATH/bin

# CMake
set -x CMAKE_GENERATOR Ninja
set -x CMAKE_C_COMPILER_LAUNCHER ccache
set -x CMAKE_CXX_COMPILER_LAUNCHER ccache

# Docker
set DOCKER_BUILDKIT 1

# OS-specific paths
switch (uname)
  case Darwin
    fish_add_path /usr/X11R6/bin       # Apple's X11
    fish_add_path /Library/TeX/texbin/ # MacTeX
end

# Interactive shells
# ---------------------------------------------------------------------
if status is-interactive
  # Vi bindings.
  fish_vi_key_bindings

  # Setup prompt
  starship init fish | source

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

  # Abbreviations: misc
  abbr n 'nvim'

  # Abbreviations: git
  abbr g 'git'
  abbr ga 'git add'
  abbr gaa 'git add --all'
  abbr gb 'git branch'
  abbr gbd 'git branch -D'
  abbr gbl 'git blame'
  abbr gc 'git commit -v'
  abbr gc! 'git commit -v --amend'
  abbr gcn! 'git commit -v --amend --no-edit'
  abbr gca 'git commit -a -v'
  abbr gca! 'git commit -a -v --amend'
  abbr gcan! 'git commit -a -v --no-edit --amend'
  abbr gcans! 'git commit -a -v -s --no-edit --amend'
  abbr gcl 'git clone --recursive'
  abbr gcf 'git config --list'
  abbr gclean 'git clean -fd'
  abbr gco 'git checkout'
  abbr gcob 'git checkout -b'
  abbr gcom 'git checkout master'
  abbr gcod 'git checkout develop'
  abbr gcof 'git checkout feat/'
  abbr gcp 'git cherry-pick'
  abbr gcpa 'git cherry-pick --abort'
  abbr gcpc 'git cherry-pick --continue'
  abbr gd 'git diff'
  abbr gdca 'git diff --cached'
  abbr gf 'git fetch'
  abbr gfa 'git fetch --all --prune'
  abbr gfo 'git fetch origin'
  abbr gl 'git log'
  abbr glg 'git log --graph'
  abbr gm 'git merge'
  abbr gp 'git push'
  abbr gpf 'git push --force'
  abbr gpt 'git push --tags'
  abbr gptf 'git push --tags --force'
  abbr gpoat 'git push origin --all && git push origin --tags'
  abbr gpoatf 'git push origin --all -f && git push origin --tags -f'
  abbr gpristine 'git reset --hard && git clean -dfx'
  abbr gpl 'git pull'
  abbr gpo 'git pull origin'
  abbr gpom 'git pull origin master'
  abbr gpu 'git pull upstream'
  abbr gpum 'git pull upstream master'
  abbr gr 'git remote -v'
  abbr gra 'git remote add'
  abbr grau 'git remote add upstream'
  abbr grrm 'git remote remove'
  abbr grmv 'git remote rename'
  abbr grset 'git remote set-url'
  abbr grb 'git rebase'
  abbr grba 'git rebase --abort'
  abbr grbc 'git rebase --continue'
  abbr grt 'git reset HEAD'
  abbr grhh 'git reset HEAD --hard'
  abbr grth 'git reset --hard'
  abbr gst 'git status'
  abbr gss 'git status -s'
  abbr gss 'git stash save'
  abbr gsa 'git stash apply'
  abbr gsd 'git stash drop'
  abbr gsp 'git stash pop'
  abbr gsu 'git submodule update'
  abbr gts 'git tag -s'

  switch (uname)
    case Darwin
      alias afk '/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
      alias hidedesktop 'defaults write com.apple.finder CreateDesktop -bool false \
        && killall Finder'
      alias showdesktop 'defaults write com.apple.finder CreateDesktop -bool true \
        && killall Finder'
  end
end
