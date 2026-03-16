#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH='' cd -- "$script_dir/.." && pwd)"
setup_script="$repo_root/config/setup-guarded-pushes"
unguard_script="$repo_root/config/unguard-pushes"
status_script="$repo_root/config/guarded-pushes-status"

tmpdirs=()
last_repo=''

cleanup() {
  local dir

  if [ "${#tmpdirs[@]}" -eq 0 ]; then
    return 0
  fi

  for dir in "${tmpdirs[@]}"; do
    if [ -n "$dir" ]; then
      rm -rf "$dir"
    fi
  done
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_unset() {
  local repo="$1"
  local key="$2"
  local message="$3"

  if git -C "$repo" config --local --get-all "$key" >/dev/null 2>&1; then
    fail "$message"
  fi
}

assert_not_exists() {
  local path="$1"
  local message="$2"

  if [ -e "$path" ]; then
    fail "$message"
  fi
}

git_common_dir() {
  local repo="$1"
  local path

  path="$(git -C "$repo" rev-parse --git-common-dir)"
  case "$path" in
    /*)
      printf '%s\n' "$path"
      ;;
    *)
      printf '%s\n' "$repo/$path"
      ;;
  esac
}

make_repo() {
  local tmpdir repo remote_url

  tmpdir="$(mktemp -d)"
  tmpdirs+=("$tmpdir")
  repo="$tmpdir/repo"
  mkdir -p "$repo"

  git -C "$repo" init -q -b main
  : > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" -c user.name=Test -c user.email=test@example.com commit -qm init
  remote_url='git@github.com:example/project.git'
  git -C "$repo" remote add origin "$remote_url"

  last_repo="$repo"
}

test_single_remote_pushurl_behavior() {
  local repo include_path status_output

  make_repo
  repo="$last_repo"

  "$setup_script" "$repo" >/dev/null

  assert_eq https://github.com/example/project.git \
    "$(git -C "$repo" remote get-url origin)" \
    'setup should normalize origin to HTTPS for fetch/topic pushes'
  assert_eq origin "$(git -C "$repo" config --local --get branch.main.pushRemote)" \
    'guarded branches should push to origin by default'
  assert_eq git@github.com:example/project.git \
    "$(git -C "$repo" remote get-url --push origin)" \
    'main should push via SSH through the guarded include'

  git -C "$repo" checkout -q -b topic/demo
  assert_eq https://github.com/example/project.git \
    "$(git -C "$repo" remote get-url --push origin)" \
    'topic branches should still push via HTTPS'

  git -C "$repo" checkout -q main
  include_path="$(git_common_dir "$repo")/$(git -C "$repo" config --local --get hooks.protectedPushIncludePath)"
  if [ ! -f "$include_path" ]; then
    fail 'setup should create the guarded include file'
  fi

  status_output="$("$status_script" "$repo")"
  case "$status_output" in
    *'current push mode: SSH'*)
      ;;
    *)
      fail 'status helper should report SSH mode on guarded branches'
      ;;
  esac
}

test_round_trip_restores_original_remote_state() {
  local repo include_path

  make_repo
  repo="$last_repo"
  git -C "$repo" config --local branch.main.pushRemote upstream
  git -C "$repo" config --local remote.origin.pushurl ssh://git@github.com/example/project.git

  "$setup_script" "$repo" >/dev/null
  assert_eq origin "$(git -C "$repo" config --local --get branch.main.pushRemote)" \
    'setup should replace the guarded branch pushRemote while active'

  include_path="$(git_common_dir "$repo")/$(git -C "$repo" config --local --get hooks.protectedPushIncludePath)"
  "$unguard_script" "$repo" >/dev/null

  assert_eq git@github.com:example/project.git \
    "$(git -C "$repo" remote get-url origin)" \
    'unguard should restore the original origin URL'
  assert_eq ssh://git@github.com/example/project.git \
    "$(git -C "$repo" config --local --get remote.origin.pushurl)" \
    'unguard should restore the original local pushurl'
  assert_eq upstream "$(git -C "$repo" config --local --get branch.main.pushRemote)" \
    'unguard should restore the original branch pushRemote'
  assert_not_exists "$include_path" 'unguard should remove the managed include file'
  assert_unset "$repo" hooks.protectedPushIncludePath 'unguard should remove include metadata'
}

test_legacy_multi_remote_migrates_cleanly() {
  local repo

  make_repo
  repo="$last_repo"
  git -C "$repo" remote set-url origin https://github.com/example/project.git
  git -C "$repo" remote add origin-ssh git@github.com:example/project.git
  git -C "$repo" config --local branch.main.remote origin-ssh
  git -C "$repo" config --local branch.main.pushRemote origin-ssh
  git -C "$repo" config --local hooks.protectedBranches main
  git -C "$repo" config --local hooks.protectedPushManagedBranches main
  git -C "$repo" config --local hooks.protectedPushPrimaryRemote origin
  git -C "$repo" config --local hooks.protectedPushSshRemote origin-ssh
  git -C "$repo" config --local hooks.protectedPushPrimaryRemoteOriginalUrl git@github.com:example/project.git
  git -C "$repo" config --local hooks.protectedPushOriginalPushDefault __unset__
  git -C "$repo" config --local hooks.protectedPushOriginalSshRemoteUrl __missing__
  git -C "$repo" config --local hooks.protectedPushOriginalSshFetch __none__

  "$unguard_script" "$repo" >/dev/null
  "$setup_script" "$repo" >/dev/null

  assert_eq https://github.com/example/project.git \
    "$(git -C "$repo" remote get-url origin)" \
    'migration should keep origin on HTTPS after re-setup'
  assert_eq origin "$(git -C "$repo" config --local --get branch.main.remote)" \
    'migration should restore guarded branches to tracking origin'
  assert_eq origin "$(git -C "$repo" config --local --get branch.main.pushRemote)" \
    'migration should collapse guarded pushes back to origin'
  assert_eq git@github.com:example/project.git \
    "$(git -C "$repo" remote get-url --push origin)" \
    'migration should make guarded pushes use SSH through origin'
  if git -C "$repo" remote get-url origin-ssh >/dev/null 2>&1; then
    fail 'migration should remove the legacy origin-ssh remote when it was tool-managed'
  fi
}

test_single_remote_pushurl_behavior
test_round_trip_restores_original_remote_state
test_legacy_multi_remote_migrates_cleanly

printf 'ok: guarded push tests passed\n'
