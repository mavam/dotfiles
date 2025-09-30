# Unless -f is specified, .zshenv is sourced on all shell invocations.
# Consequently, there should be only critical commands environment in this file.

umask 022

# Set $PATH.
if [[ -f ~/.zpath ]]; then
  source ~/.zpath
fi

# Editor
if which vim &> /dev/null; then
  export EDITOR="vim"
elif which vi &> /dev/null; then
  export EDITOR="vi"
fi
export VISUAL=$EDITOR

# Pager.
export PAGER="less -S"

# Version control software.
export CVS_RSH="ssh"
export CVSEDITOR="vim"
export RSYNC_RSH="ssh"

# OS-specific environment.
case $OSTYPE in
  linux*)
    [[ -d ~/.linuxbrew ]] && eval $(~/.linuxbrew/bin/brew shellenv)
    ;;
  darwin*)
    # Ignore reading of /etc/profile, which messes with $PATH. We re-enable
    # reading other system-wide zsh files in ~/.zprofile. See
    # http://www.zsh.org/mla/users/2015/msg00725.html for details.
    setopt no_global_rcs
    # Opt out of Homebrew analytics.
    export HOMEBREW_NO_ANALYTICS=1
    # Default to Homebrew-provided cutting-edge C++ compiler 
    llvm_prefix=$(brew --prefix llvm 2> /dev/null)
    if [[ -d "${llvm_prefix}" ]]; then
      export CC="${llvm_prefix}/bin/clang"
      export CXX="${llvm_prefix}/bin/clang++"
      export CPPFLAGS="-isystem ${llvm_prefix}/include ${CPPFLAGS}"
      export CXXFLAGS="-isystem ${llvm_prefix}/include/c++/v1 ${CXXFLAGS}"
      export LDFLAGS="-Wl,-rpath,${llvm_prefix} ${LDFLAGS}"
    fi
    ;;
esac

# Sane CMake defaults
export CMAKE_GENERATOR="Ninja"
export CMAKE_C_COMPILER_LAUNCHER="ccache"
export CMAKE_CXX_COMPILER_LAUNCHER="ccache"

# Docker
export DOCKER_BUILDKIT=1

# Set UTF-8 locale.
export LANG=en_US.UTF-8

# Source local environment.
if [[ -f ~/.zshenv.local ]]; then
  source ~/.zshenv.local
fi

# vim: ft=zsh
