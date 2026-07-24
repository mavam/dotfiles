#!/usr/bin/env bash
# Claude Code statusline: a best-effort port of pi-fancy-footer.
#
# Reads the statusline JSON on stdin and renders two rows mirroring the
# pi footer's default layout (nerd icons, parallelogram gauges):
#
#   row 0:  context gauge · Claude quota gauges      cache r/w · hit rate · cost
#   row 1:  repo · branch · PR · diff · ahead/behind            model · thinking
#
# Omitted vs. the pi footer (needs background fetching): Codex quota,
# PR review threads, PR CI status, cumulative cache totals (per-turn here).
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

# "." decimals for printf/awk output regardless of environment.
export LC_ALL=en_US.UTF-8

input=$(cat)

eval "$(jq -r '@sh "
  model=\(.model.display_name // "Claude")
  used_pct=\(.context_window.used_percentage // 0)
  cost=\(.cost.total_cost_usd // 0)
  cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)
  cache_write=\(.context_window.current_usage.cache_creation_input_tokens // 0)
  in_tokens=\(.context_window.current_usage.input_tokens // 0)
  thinking=\(.thinking.enabled // false)
  effort=\(.effort.level // "")
  repo=\(.workspace.repo.name // "")
  cwd=\(.workspace.current_dir // .cwd // ".")
  pr_number=\(.pr.number // 0)
  pr_url=\(.pr.url // "")
  rl5_used=\(.rate_limits.five_hour.used_percentage // -1)
  rl7_used=\(.rate_limits.seven_day.used_percentage // -1)
"' <<<"$input")"

# ── Theme: fancy-footer named colors → ANSI ─────────────────────────────
ESC=$'\033'
c_text="${ESC}[39m"        # icons (defaultIconColor: text)
c_muted="${ESC}[90m"       # widget text (defaultTextColor: muted)
c_dim="${ESC}[2;90m"       # empty gauge cells
c_ok="${ESC}[32m"          # gaugeColors.ok: success
c_warn="${ESC}[33m"        # gaugeColors.warning
c_err="${ESC}[31m"         # gaugeColors.error
c_accent="${ESC}[36m"      # git ahead/diverged marker
r="${ESC}[0m"

# ── Glyphs: iconFamily "nerd", gaugeStyle "parallelograms", width 5 ─────
# Nerd icons as UTF-8 byte escapes: private-use glyphs don't survive every
# editor/tool round-trip as literals.
G_FILLED="▰" G_EMPTY="▱" G_CELLS=5

i_ctx=$(printf '\xf3\xb0\xbe\x86')      # 󰾆 contextBarMarker U+F0F86
i_quota=$(printf '\xf3\xb0\x93\x85')    # 󰓅 providerStatus   U+F04C5
i_cache_r=$(printf '\xf3\xb0\x87\x9a')  # 󰇚 cacheRead        U+F01DA
i_cache_w=$(printf '\xf3\xb0\x95\x92')  # 󰕒 cacheWrite       U+F0552
i_hit=$(printf '\xf3\xb0\x80\x9a')      # 󰀚 cacheHitRate     U+F001A
i_cost=$(printf '\xf3\xb0\x87\x81')     # 󰇁 currency         U+F01C1
i_model=$(printf '\xf3\xb0\x9a\xa9')    # 󰚩 model            U+F06A9
i_think=$(printf '\xf3\xb0\xa7\x91')    # 󰧑 thinking         U+F09D1
i_path=$(printf '\xef\x84\x95')         #  path             U+F115
i_branch=$(printf '\xef\x90\x98')       #  branch           U+F418
i_pr=$(printf '\xef\x90\x88')           #  pullRequest      U+F408
i_ahead=$(printf '\xef\x84\x82')        #  gitAhead         U+F102
i_behind=$(printf '\xef\x84\x83')       #  gitBehind        U+F103
i_diverged=$(printf '\xef\x81\xbd')     #  gitDiverged      U+F07D
i_add="↗" i_del="↘"

# gauge LEFT_PERCENT MODE -> "filled_cells shown_pct color"
gauge() {
  awk -v left="$1" -v n="$G_CELLS" -v mode="$2" 'BEGIN {
    if (left < 0) left = 0; if (left > 100) left = 100
    shown = (mode == "remaining") ? left : 100 - left
    f = int(shown / 100 * n + 0.5)
    if (shown > 0 && f == 0) f = 1
    if (shown < 100 && f == n) f = n - 1
    pct = (shown == int(shown)) ? sprintf("%d%%", shown) : sprintf("%.1f%%", shown)
    col = (left < 25) ? "err" : (left < 60) ? "warn" : "ok"
    printf "%d %s %s", f, pct, col
  }'
}

repeat() {
  local out="" i
  for ((i = 0; i < $1; i++)); do out+="$2"; done
  printf '%s' "$out"
}

# render_gauge LEFT_PERCENT MODE -> colored gauge + percent label
render_gauge() {
  local f pct col cvar
  read -r f pct col <<<"$(gauge "$1" "$2")"
  case $col in ok) cvar=$c_ok ;; warn) cvar=$c_warn ;; *) cvar=$c_err ;; esac
  printf '%s' "${cvar}$(repeat "$f" "$G_FILLED")${r}${c_dim}$(repeat $((G_CELLS - f)) "$G_EMPTY")${r}${c_muted} ${pct}${r}"
}

# Compact token counts: 246, 1.2k, 246k, 1.2M, 12M
fmt_tokens() {
  awk -v c="$1" 'BEGIN {
    if (c < 1000) { printf "%d", c; exit }
    if (c < 10000) { v = sprintf("%.1f", c / 1000); sub(/\.0$/, "", v); printf "%sk", v; exit }
    if (c < 999500) { printf "%dk", int(c / 1000 + 0.5); exit }
    if (c < 10000000) { v = sprintf("%.1f", c / 1e6); sub(/\.0$/, "", v); printf "%sM", v; exit }
    printf "%dM", int(c / 1e6 + 0.5)
  }'
}

# Icon glued to text, like the pi footer renders widgets.
widget() { printf '%s' "${c_text}$1${r}${c_muted}$2${r}"; }

hyperlink() { printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$1" "$2"; }

# Display width as Claude Code's truncation counts it: strips OSC 8 links
# and SGR codes, then counts private-use glyphs (nerd icons) as 2 columns.
vislen() {
  printf '%s' "$1" | perl -CSD -0777 -ne '
    s/\x1b\]8;;[^\x07\x1b]*(\x07|\x1b\\)//g;
    s/\x1b\[[0-9;]*m//g;
    my $w = 0;
    for my $o (map { ord } split //) {
      $w += ($o >= 0xE000 && $o <= 0xF8FF) || $o >= 0xF0000 ? 2 : 1;
    }
    print $w;'
}

compose_row() {
  local left=$1 right=$2 width=${COLUMNS:-120} gap
  gap=$((width - $(vislen "$left") - $(vislen "$right")))
  if ((gap < 1)); then gap=1; fi
  printf '%s%*s%s\n' "$left" "$gap" "" "$right"
}

join() {
  local out="" part
  for part in "$@"; do
    [[ -z $part ]] && continue
    [[ -n $out ]] && out+=" "
    out+="$part"
  done
  printf '%s' "$out"
}

# ── Git (single fast status call + numstat) ─────────────────────────────
branch="" ahead=0 behind=0 added=0 removed=0
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r line; do
    case $line in
      "# branch.head "*) branch=${line#"# branch.head "} ;;
      "# branch.ab "*)
        set -- $line
        ahead=${3#+} behind=${4#-}
        ;;
    esac
  done < <(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null | sed -n '1,4p')
  read -r added removed <<<"$(git -C "$cwd" --no-optional-locks diff --numstat HEAD 2>/dev/null |
    awk '{a += $1; d += $2} END {printf "%d %d", a, d}')" || true
fi
[[ $branch == "(detached)" ]] && branch=""

# ── Row 0: context gauge + quota (left) · cache + cost (right) ──────────
ctx_left=$(awk -v u="$used_pct" 'BEGIN {printf "%g", 100 - u}')
w_ctx="${c_text}${i_ctx}${r}$(render_gauge "$ctx_left" used)"

w_quota=""
if awk -v a="$rl5_used" -v b="$rl7_used" 'BEGIN {exit !(a >= 0 || b >= 0)}'; then
  parts="${c_text}${i_quota}${r}"
  glue=""
  if awk -v u="$rl5_used" 'BEGIN {exit !(u >= 0)}'; then
    parts+="${glue}${c_muted}5h${r} $(render_gauge "$(awk -v u="$rl5_used" 'BEGIN {printf "%g", 100 - u}')" remaining)"
    glue=" "
  fi
  if awk -v u="$rl7_used" 'BEGIN {exit !(u >= 0)}'; then
    parts+="${glue}${c_muted}7d${r} $(render_gauge "$(awk -v u="$rl7_used" 'BEGIN {printf "%g", 100 - u}')" remaining)"
  fi
  w_quota=$parts
fi

w_cache_r="" w_cache_w="" w_hit=""
((cache_read > 0)) && w_cache_r=$(widget "$i_cache_r" "$(fmt_tokens "$cache_read")")
((cache_write > 0)) && w_cache_w=$(widget "$i_cache_w" "$(fmt_tokens "$cache_write")")
if ((cache_read > 0 || cache_write > 0)); then
  hit=$(awk -v r="$cache_read" -v w="$cache_write" -v i="$in_tokens" \
    'BEGIN {t = i + r + w; if (t > 0) printf "%.1f%%", r / t * 100}')
  [[ -n $hit ]] && w_hit=$(widget "$i_hit" "$hit")
fi

w_cost=""
if awk -v c="$cost" 'BEGIN {exit !(c > 0)}'; then
  w_cost=$(widget "$i_cost" "$(awk -v c="$cost" 'BEGIN {printf "%.2f", c}')")
fi

# ── Row 1: location + git (left) · model + thinking (right) ─────────────
loc=$repo
if [[ -z $loc ]]; then loc=$(basename "$cwd"); fi
w_loc=$(widget "$i_path" "$loc")

w_branch="" w_pr="" w_add="" w_del="" w_git=""
[[ -n $branch ]] && w_branch=$(widget "$i_branch" "$branch")
if ((pr_number > 0)); then
  w_pr=$(widget "$i_pr" "$(hyperlink "$pr_url" "$pr_number")")
fi
((added > 0)) && w_add=$(widget "$i_add" "$added")
((removed > 0)) && w_del=$(widget "$i_del" "$removed")
if ((ahead > 0 && behind > 0)); then
  w_git="${c_accent}${i_diverged}${r}${c_muted}${ahead}/${behind}${r}"
elif ((ahead > 0)); then
  w_git="${c_accent}${i_ahead}${r}${c_muted}${ahead}${r}"
elif ((behind > 0)); then
  w_git="${c_warn}${i_behind}${r}${c_muted}${behind}${r}"
fi

w_model=$(widget "$i_model" "$model")
w_think=""
if [[ $thinking == true ]]; then
  w_think=$(widget "$i_think" "${effort:-on}")
fi

compose_row "$(join "$w_ctx" "$w_quota")" "$(join "$w_cache_r" "$w_cache_w" "$w_hit" "$w_cost")"
compose_row "$(join "$w_loc" "$w_branch" "$w_pr" "$w_add" "$w_del" "$w_git")" "$(join "$w_model" "$w_think")"
