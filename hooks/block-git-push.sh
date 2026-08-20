#!/usr/bin/env bash
# PreToolUse(Bash) hook: 메인 계열 브랜치로의 git push만 차단.
# 정책(~/.claude/CLAUDE.md): main/master/prod/production/develop 로의 push·merge는
# 사용자가 직접. 그 외 feature/fix 브랜치는 자동 push 허용.
#
# 동작:
#   - git push 가 아니면 통과.
#   - 명시적 refspec(`git push origin main`, `feature:main`, `--delete main`)의
#     목적지가 메인 계열이면 deny.
#   - refspec 없는 bare push 는 현재 브랜치를 해석해 메인 계열이면 deny.
#   - 브랜치를 확정할 수 없으면 안전상 deny(fail-safe).

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# git push 호출 탐지 (기존 정규식 재사용)
if ! printf '%s' "$cmd" | grep -Eq 'git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|--?[^[:space:]]+))*[[:space:]]+push([[:space:]]|$)'; then
  exit 0
fi

deny() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}
REASON_MAIN="메인 계열 브랜치(main/master/prod/production/develop)로의 push는 차단됩니다(~/.claude/CLAUDE.md). 이 브랜치로의 push는 사용자가 직접 수행하세요. (그 외 브랜치는 허용)"
REASON_UNKNOWN="push 대상 브랜치를 확정할 수 없어 안전상 차단합니다. 메인 계열이 아니면 직접 push 하세요."

is_protected() {
  [[ "$1" =~ ^(main|master|prod|production|develop)$ ]]
}

# 신규 리포(초기 셋업) 예외 목록: 이 경로에서는 main push 허용
is_exempt_repo() {
  local exempt_repos=(
    "/Users/jax/sources/wim_backoffice_app"
    "/Users/jax/.claude"
  )
  local resolved_gitdir
  resolved_gitdir=$(cd "$gitdir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || true)
  for repo in "${exempt_repos[@]}"; do
    [[ "$resolved_gitdir" == "$repo" ]] && return 0
  done
  return 1
}

# 현재 브랜치 해석용 디렉토리: -C <dir> > 선행 `cd <dir>` > 현재 cwd
gitdir="."
if [[ "$cmd" =~ (^|[[:space:]])-C[[:space:]]+([^[:space:]]+) ]]; then
  gitdir="${BASH_REMATCH[2]}"
elif [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\&\;\|]+) ]]; then
  gitdir="${BASH_REMATCH[1]}"
fi
# ~ 확장 (eval 없이)
case "$gitdir" in
  "~") gitdir="$HOME" ;;
  "~/"*) gitdir="$HOME/${gitdir#\~/}" ;;
esac

# push 이후 인자만 추출, 셸 구분자 전까지
after="${cmd#*push}"
after="${after%%&&*}"; after="${after%%||*}"; after="${after%%;*}"; after="${after%%|*}"

read -ra toks <<< "$after"
positionals=()
skip_next=0
for t in "${toks[@]}"; do
  if [[ $skip_next -eq 1 ]]; then skip_next=0; continue; fi
  case "$t" in
    --repo|--receive-pack|--exec|-o|--push-option) skip_next=1 ;;  # 값을 받는 옵션
    -*) : ;;                                                       # 기타 플래그 무시
    *) positionals+=("$t") ;;                                      # remote/refspec
  esac
done

# 첫 포지셔널 = remote, 나머지 = refspec
refspecs=("${positionals[@]:1}")

if is_exempt_repo; then
  exit 0
fi

if [[ ${#refspecs[@]} -eq 0 ]]; then
  cur=$(git -C "$gitdir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -z "$cur" || "$cur" == "HEAD" ]]; then
    deny "$REASON_UNKNOWN"
  fi
  if is_protected "$cur"; then
    deny "$REASON_MAIN"
  fi
  exit 0
fi

for r in "${refspecs[@]}"; do
  dst="${r##*:}"     # src:dst → dst, 단일이면 전체
  dst="${dst#+}"     # 강제 push(+) 접두 제거
  if [[ "$dst" == "HEAD" ]]; then
    cur=$(git -C "$gitdir" rev-parse --abbrev-ref HEAD 2>/dev/null)
    dst="$cur"
  fi
  if is_protected "$dst"; then
    deny "$REASON_MAIN"
  fi
done

exit 0
