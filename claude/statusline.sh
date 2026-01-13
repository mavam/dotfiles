#!/bin/bash

E="\033[" R="\033[0m"
GRN="0;32" YLW="0;33" RED="0;31"
DG="2;32" DY="2;33" DR="2;31" DW="2;37" DC="2;36"
CYN="0;36" BLU="0;34" MAG="0;35" WHT="0;37"
COLS=$(tput cols 2>/dev/null || echo 120)

parse_input() {
  eval "$(jq -r '
    @sh "MODEL=\(.model.display_name // "Claude" | sub("Claude "; ""))",
    @sh "CWD=\(.workspace.current_dir // env.PWD)",
    @sh "LINES_ADD=\(.cost.total_lines_added // 0)",
    @sh "LINES_DEL=\(.cost.total_lines_removed // 0)",
    @sh "DURATION_MS=\(.cost.total_duration_ms // 0)",
    @sh "COST_USD=\(.cost.total_cost_usd // 0)",
    @sh "TOTAL_TOK=\(.context_window.context_window_size // 200000)",
    @sh "USED_PCT=\(.context_window.used_percentage // 0)",
    @sh "IN_TOK=\(.context_window.current_usage.input_tokens // 0)",
    @sh "CC_TOK=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
    @sh "CR_TOK=\(.context_window.current_usage.cache_read_input_tokens // 0)"
  ' <<<"$INPUT")"
}

get_git() {
  BRANCH="" COMMIT="" GITHUB="" GIT_STATUS=""
  cd "$CWD" 2>/dev/null || return
  git rev-parse --git-dir &>/dev/null || return

  BRANCH=$(git branch --show-current 2>/dev/null)
  COMMIT=$(git rev-parse --short HEAD 2>/dev/null)

  local url=$(git config --get remote.origin.url 2>/dev/null)
  [[ $url =~ github.com[:/](.+/.+)(\.git)?$ ]] && GITHUB="${BASH_REMATCH[1]%.git}"

  local p=$(git status --porcelain 2>/dev/null)
  if [[ -n "$p" ]]; then
    local s=0 m=0 u=0
    while IFS= read -r l; do
      [[ "${l:0:1}" == "?" ]] && ((u++)) && continue
      [[ "${l:0:1}" != " " ]] && ((s++))
      [[ "${l:1:1}" != " " && "${l:1:1}" != "?" ]] && ((m++))
    done <<<"$p"
    ((s)) && GIT_STATUS+="${E}${DG}m●${E}${DW}m$s$R "
    ((m)) && GIT_STATUS+="${E}${DY}m●${E}${DW}m$m$R "
    ((u)) && GIT_STATUS+="${E}${DC}m○${E}${DW}m$u$R"
  fi

  local up=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null) || true
  if [[ -n "$up" ]]; then
    local a=$(git rev-list --count "$up"..HEAD 2>/dev/null) || a=0
    local b=$(git rev-list --count HEAD.."$up" 2>/dev/null) || b=0
    ((a)) && GIT_STATUS+=" ${E}${CYN}m↑${E}${DW}m$a$R"
    ((b)) && GIT_STATUS+=" ${E}${CYN}m↓${E}${DW}m$b$R"
  fi
}

build_bricks() {
  local n=40
  ((COLS < 100)) && n=30
  ((COLS < 80)) && n=20
  local t1=$((n * 60 / 100)) t2=$((n * 85 / 100))
  local cached=$(((CR_TOK + CC_TOK) * n / TOTAL_TOK))
  local fresh=$((IN_TOK * n / TOTAL_TOK))
  ((CR_TOK + CC_TOK > 0 && cached == 0)) && cached=1
  ((IN_TOK > 0 && fresh == 0)) && fresh=1

  local out="" i c
  for ((i = 0; i < cached; i++)); do
    ((i < t1)) && c=$DG || { ((i < t2)) && c=$DY || c=$DR; }
    out+="${E}${c}m■$R"
  done
  for (( ; i < cached + fresh; i++)); do
    ((i < t1)) && c=$GRN || { ((i < t2)) && c=$YLW || c=$RED; }
    out+="${E}${c}m■$R"
  done
  for (( ; i < n; i++)); do
    ((i < t1)) && c=$DG || { ((i < t2)) && c=$DY || c=$DR; }
    out+="${E}${c}m□$R"
  done
  echo "$out"
}

format_line1() {
  local bricks=$(build_bricks)
  local pc
  ((USED_PCT < 60)) && pc=$GRN || { ((USED_PCT < 85)) && pc=$YLW || pc=$RED; }

  local out="${E}${WHT}m$MODEL$R $bricks ${E}${pc}m${USED_PCT}%$R"

  if ((COLS >= 50)); then
    local uk=$(((CR_TOK + CC_TOK + IN_TOK) / 1000)) tk=$((TOTAL_TOK / 1000))
    out+=" ${E}${WHT}m${uk}k${E}${DW}m/${E}${WHT}m${tk}k$R"
  fi
  if ((COLS >= 55)); then
    local h=$((DURATION_MS / 3600000)) m=$(((DURATION_MS % 3600000) / 60000))
    out+=" ${E}${MAG}m${h}h ${m}m$R"
  fi
  if ((COLS >= 60)) && [[ "$COST_USD" != "0" && "$COST_USD" != "0.0" && -n "$COST_USD" ]]; then
    local cost=$(printf "%.2f" "$COST_USD" 2>/dev/null || echo "$COST_USD")
    out+=" ${E}${YLW}m\$${cost}$R"
  fi
  echo "$out"
}

format_line2() {
  local out=""
  [[ -n "$GITHUB" ]] && out+="${E}${CYN}m$GITHUB$R " || out+="${E}${DW}m${CWD/#$HOME/\~}$R "
  [[ -n "$BRANCH" ]] && out+="${E}${BLU}m$BRANCH$R"
  [[ -n "$COMMIT" ]] && out+=" ${E}${YLW}m$COMMIT$R"
  ((LINES_ADD || LINES_DEL)) && out+=" ${E}${GRN}m+$LINES_ADD$R/${E}${RED}m-$LINES_DEL$R"
  [[ -n "$GIT_STATUS" ]] && out+=" $GIT_STATUS"
  echo "$out"
}

INPUT=$(cat)
parse_input
get_git
echo -e "$(format_line1)"
echo -e "$(format_line2)"
