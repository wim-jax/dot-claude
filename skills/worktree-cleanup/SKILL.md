---
name: worktree-cleanup
description: WIM 백오피스 워크트리·브랜치 정리 런북 — 엄브렐러 + 서브모듈(backend·kb-service·wimmy) 전체에서 완전 흡수(fully-merged)된 브랜치와 stale 워크트리를 안전하게 일괄 삭제. "워크트리 정리/브랜치 정리/브랜치 청소/cleanup branches/stale worktree 지워" 요청 시 사용. 미머지·squash-only·protected·CI 인프라 브랜치는 절대 건드리지 않는다.
---

# 워크트리·브랜치 정리 런북

"워크트리 및 브랜치 정리" 류 요청 시 이 절차를 따른다. **핵심 원칙: 복원 가능성(reversibility)이 유일한 삭제 기준.** 완전 흡수된(merge-commit으로 staging/main 히스토리에 남은) 브랜치만 삭제하고, 유실 위험이 있는 건 하나도 건드리지 않는다.

이 레포는 **엄브렐러 + 서브모듈 3개(`backend`·`kb-service`·`wimmy`) + 별도 레포 2개(`frontend`·`naeo`)** 구조다. 각 레포가 독립된 브랜치·워크트리를 가지므로 **엄브렐러만 정리하면 VSCode 소스컨트롤에 나머지 레포 브랜치가 그대로 남는다.** 반드시 **6개 레포 전부**(`.`·`backend`·`kb-service`·`wimmy`·`frontend`·`naeo`)를 순회한다.
- `frontend`(wim_backoffice_frontend)·`naeo`(wim_naeo)는 이 모노레포 디렉터리 안에 있지만 **git 서브모듈이 아닌 독립 clone**이다. `git -C frontend`·`git -C naeo`로 각각 다룬다.
- **6개 레포 전부 base=`origin/staging`이다** — `frontend`·`naeo`도 default가 `main`이지만 배포 흐름은 `feature→staging→main`이라 판정 base는 staging. HEAD branch(default)가 main이라고 main 대비로 재면 안 된다(미승격 흡수분을 전부 미머지로 오판).

## 0) 삭제/보존 판정 기준

**삭제 OK** — `git rev-list --count origin/<base>..<branch>` == 0 (base에 완전 흡수 = merge-commit으로 히스토리에 tip 보존 = `git branch <name> <sha>`로 무손실 복원 가능).
- **base는 `origin/staging`이다.** 이 시스템의 작업 브랜치(`feat/*`·`fix/*`·`docs/*`·`chore/*`)는 전부 `staging`으로 머지된다(staging→main은 릴리스 승격). main 대비로 재면 아직 승격 안 된 흡수 브랜치가 미머지로 오판되니 **반드시 `origin/staging` 대비**로 판정한다.
- upstream이 `gone`(원격 삭제됨)이고 ahead==0이면 로컬만 정리 대상.

**보존(삭제 금지)**:
1. **미머지** — `origin/staging..` ahead > 0 (staging에 없는 커밋 보유 = 유실 위험). 로컬 전용(upstream 없음) 브랜치도 여기 해당하면 남긴다.
   - **frontend `promote/*`** — 릴리스가 staging→main 승격용으로 만드는 브랜치. staging 대비 ahead가 수백(오래된 base에서 분기)이라 미머지로 잡혀 자동 제외된다. 실제 머지됐어도 자동 삭제 대상에서 빼고 손대지 않는다(정리하려면 사용자 확인).
   - **워크트리에 untracked/미커밋 파일이 남은 흡수 브랜치** — 브랜치 자체는 ahead=0이라도 워크트리에 있는 untracked 파일은 제거 시 유실된다. 워크트리를 남기고 사용자에게 보고(예: naeo `feat/naeo-request-cards`의 `eslint.config.js`).
2. **squash-only 머지** — 원본 커밋이 staging에 없어 복원 불가. ahead>0으로 보여 자동 대상에서 자연 제외됨(이 레포는 merge-commit 정책이라 보통 없음).
3. **protected** — `main`·`staging`(+ `master`·`develop`·`prod`·`production` 및 각 레포 default). 절대 삭제·push 금지.
4. **CI 인프라 브랜치** — 🚨 **`hotfix-base`(원격, 엄브렐러)** 절대 삭제 금지. TeamCity `Hotfix` 프로젝트 VCS root의 default 브랜치라 원격에 없으면 모든 `hotfix/*` 빌드가 change collection 단계에서 실패한다(사고 2026-08-03). 머지된 것처럼 보여도(ahead==0) 삭제 목록에서 제외. `--prune`은 원격을 지우지 않으니 안전하지만, `push --delete` 목록엔 절대 넣지 않는다.

## 1) 실측 (레포별)

각 레포에서 fetch/prune 후 워크트리·브랜치 흡수 여부를 뽑는다. **6개 레포 전부** 순회:

```bash
cd /Users/jax/sources/wim_backoffice
for r in . backend kb-service wimmy frontend naeo; do
  echo "========== $r =========="
  git -C "$r" fetch --all --prune 2>&1 | tail -2
  git -C "$r" worktree list
  for b in $(git -C "$r" for-each-ref --format='%(refname:short)' refs/heads/); do
    case "$b" in staging|main|master|develop|prod|production|hotfix-base) continue;; esac
    st=$(git -C "$r" rev-list --count origin/staging..$b 2>/dev/null)
    up=$(git -C "$r" rev-parse --abbrev-ref --symbolic-full-name "$b@{u}" 2>/dev/null || echo none)
    printf "  %-46s staging_ahead=%-4s upstream=%s\n" "$b" "${st:-NA}" "$up"
  done
done
```

`staging_ahead=0` = 삭제 후보. `>0` = 보존. 판정이 애매하면 `gh pr view`·`git log origin/staging --oneline | grep <branch>`로 실제 머지 여부를 교차 확인한다(TODO 서술이나 브랜치명만 믿지 말 것).

## 2) 워크트리 제거 (dirty 체크 먼저)

워크트리는 실행환경(`node_modules`·`.gradle` 등)을 심볼릭 링크로 물고 있으므로 status에서 그것들을 제외하고 **실제 미커밋 변경**만 본다. dirty면 남기고 사용자에게 보고, clean이면 제거:

```bash
# 각 레포에서 (예: backend)
git -C backend status --porcelain   # 워크트리별로 확인하려면 git -C <worktree경로>
git -C backend worktree remove <worktree경로>    # clean만
git -C backend worktree prune
```

흡수된(staging_ahead=0) 브랜치를 체크아웃한 워크트리만 제거한다. 미머지 브랜치의 워크트리는 남긴다.

## 3) 로컬 브랜치 삭제 — ⚠️ zsh 함정

**이 환경 셸은 zsh다. zsh는 비인용 변수(`$BR`)를 단어분할하지 않는다** → `for b in $BR` 하면 전체가 한 덩어리 브랜치명으로 들어가 실패한다. 반드시 **배열**을 쓰거나 `git branch -D`에 브랜치를 **직접 나열**한다:

```bash
git -C backend branch -D \
  feat/foo feat/bar fix/baz ...     # staging_ahead=0 인 것만 나열
# 또는 배열:  todelete=(feat/foo feat/bar); git -C backend branch -D $todelete
```

`-D`(대문자) 사용 — `-d`는 현재 HEAD(로컬 staging) 기준 머지만 인정해서, origin/staging엔 있지만 로컬 staging이 뒤처져 있으면 거부할 수 있다. 이미 §0/§1에서 `origin/staging..`==0을 실측했으므로 `-D`가 맞다.

## 4) 원격 브랜치 삭제

작업 브랜치(`feat/*`·`fix/*`·`docs/*`·`chore/*`·`ci/*`)는 origin에서도 삭제 허용(사용자가 정리 요청 시 origin+local 일괄). **원격에 실제 존재하는 것만** 골라서(gone은 이미 §1 prune으로 정리됨) 삭제하고, **`hotfix-base`·`main`·`staging`·기타 protected는 목록에서 제외**:

```bash
git -C backend ls-remote --heads origin | awk '{sub("refs/heads/","",$2); print $2}' | sort > /tmp/rh.txt
cand=(feat/foo feat/bar ...)           # 삭제 확정 목록(§0 통과분)
todelete=(); for b in $cand; do grep -qx "$b" /tmp/rh.txt && todelete+=("$b"); done
git -C backend push origin --delete $todelete
```

**절대 금지**: `hotfix-base`, `main`, `staging`(및 각 레포 default) push --delete. 삭제 전 `todelete` 배열을 눈으로 검수한다.

## 5) 보고

레포별로 [삭제한 워크트리 수 / 로컬 브랜치 수 / 원격 브랜치 수]와 **보존 목록 + 사유**(미머지 ahead 수치, protected, CI 인프라)를 표로 보고한다. 삭제분은 전부 staging 머지커밋에 tip이 남아 `git branch <name> <sha>`로 복원 가능함을 명시한다.

## 체크리스트

- [ ] 6개 레포(`.`·`backend`·`kb-service`·`wimmy`·`frontend`·`naeo`) 전부 순회했나
- [ ] 판정 base가 `origin/staging`인가 (main 아님)
- [ ] `hotfix-base` 원격을 삭제 목록에서 제외했나
- [ ] `main`/`staging`/default 제외했나
- [ ] 미머지(ahead>0)·로컬 전용 미머지 전부 보존했나
- [ ] 워크트리 dirty 체크 후 clean만 제거했나
- [ ] zsh 단어분할 함정 피해서(배열/직접 나열) 삭제했나
- [ ] 원격 삭제 전 `todelete` 배열 눈으로 검수했나
