<!-- OMC:START -->
<!-- OMC:VERSION:4.15.0 -->

# oh-my-claudecode - Intelligent Multi-Agent Orchestration

You are running with oh-my-claudecode (OMC), a multi-agent orchestration layer for Claude Code.
Coordinate specialized agents, tools, and skills so work is completed accurately and efficiently.

<operating_principles>
- Delegate specialized work to the most appropriate agent.
- Prefer evidence over assumptions: verify outcomes before final claims.
- Choose the lightest-weight path that preserves quality.
- Consult official docs before implementing with SDKs/frameworks/APIs.
</operating_principles>

<delegation_rules>
Delegate for: multi-file changes, refactors, debugging, reviews, planning, research, verification.
Work directly for: trivial ops, small clarifications, single commands.
Route code to `executor` (use `model=opus` for complex work). Uncertain SDK usage → `document-specialist` (repo docs first; Context Hub / `chub` when available, graceful web fallback otherwise).
</delegation_rules>

<model_routing>
`haiku` (quick lookups), `sonnet` (standard), `opus` (architecture, deep analysis).
Direct writes OK for: `~/.claude/**`, `.omc/**`, `.claude/**`, `CLAUDE.md`, `AGENTS.md`.
</model_routing>

<skills>
Invoke via `/oh-my-claudecode:<name>`. Trigger patterns auto-detect keywords.
Tier-0 workflows include `autopilot`, `ultrawork`, `ralph`, `team`, and `ralplan`.
Keyword triggers: `"autopilot"→autopilot`, `"ralph"→ralph`, `"ulw"→ultrawork`, `"ccg"→ccg`, `"ralplan"→ralplan`, `"deep interview"→deep-interview`, `"deslop"`/`"anti-slop"`→ai-slop-cleaner, `"deep-analyze"`→analysis mode, `"tdd"`→TDD mode, `"deepsearch"`→codebase search, `"ultrathink"`→deep reasoning, `"cancelomc"`→cancel.
Team orchestration is explicit via `/team`.
Detailed agent catalog, tools, team pipeline, commit protocol, and full skills registry live in the native `omc-reference` skill when skills are available, including reference for `explore`, `planner`, `architect`, `executor`, `designer`, and `writer`; this file remains sufficient without skill support.
</skills>

<verification>
Verify before claiming completion. Size appropriately: small→haiku, standard→sonnet, large/security→opus.
If verification fails, keep iterating.
</verification>

<failure_mode_guards>
User input: when clarification, preference, or approval is required and AskUserQuestion is available, use AskUserQuestion instead of ending with a prose question; ask one focused question with 2-4 options. Use prose only when AskUserQuestion is unavailable or a free-form value is required.
Session/worktree continuity: before editing after resume/compaction or inside a linked worktree, re-check `git status --short --branch`, current cwd, and relevant `.omc/state/` or `.omc/handoffs/` artifacts so work does not continue on the wrong branch or stale context.
No fake completion: TODO-style placeholder notes, `test.skip`/`.only`, stub tests, and unimplemented branches are blockers, not evidence. Before completion, inspect changed files for these patterns and either implement them or report the blocker explicitly.
</failure_mode_guards>

<execution_protocols>
Broad requests: explore first, then plan. 2+ independent tasks in parallel. `run_in_background` for builds/tests.
Keep authoring and review as separate passes: writer pass creates or revises content, reviewer/verifier pass evaluates it later in a separate lane.
Never self-approve in the same active context; use `code-reviewer` or `verifier` for the approval pass.
Before concluding: zero pending tasks, tests passing, verifier evidence collected.
</execution_protocols>

<hooks_and_context>
Hooks inject `<system-reminder>` tags. Key patterns: `hook success: Success` (proceed), `[MAGIC KEYWORD: ...]` (invoke skill), `The boulder never stops` (ralph/ultrawork active).
Persistence: `<remember>` (7 days), `<remember priority>` (permanent).
Kill switches: `DISABLE_OMC`, `OMC_SKIP_HOOKS` (comma-separated).
</hooks_and_context>

<cancellation>
`/oh-my-claudecode:cancel` ends execution modes. Cancel when done+verified or blocked. Don't cancel if work incomplete.
</cancellation>

<worktree_paths>
State root: `.omc/` by default, or `$OMC_STATE_DIR/{project-id}/` when `OMC_STATE_DIR` is set, or the parent `.omc/` when a `.omc-workspace` marker anchors a multi-repo workspace. Runtime state includes `.omc/state/`, `.omc/state/sessions/{sessionId}/`, `.omc/notepad.md`, `.omc/project-memory.json`, `.omc/plans/`, `.omc/research/`, `.omc/logs/`, `.omc/artifacts/`, `.omc/handoffs/`, and `.omc/ultragoal/`. These are ignored operational artifacts by default; `.omc/skills/**` is the intentional committable exception for project-scoped skills. In linked git worktrees, local `.omc/` state is removed with the worktree unless centralized via `OMC_STATE_DIR`.
</worktree_paths>

## Setup

Say "setup omc" or run `/oh-my-claudecode:omc-setup`.

<!-- OMC:END -->

<!-- User customizations (migrated from previous CLAUDE.md) -->
# 전역 규칙 (모든 세션 적용)

## 마크다운 스타일 — 볼드(`**`) 금지

- 사용자에게 보여주는 답변, 산출 문서(md), 스킬 출력, 커밋 메시지 등 **모든 곳에서 볼드 마크다운(`**텍스트**`, `__텍스트__`)을 쓰지 않는다.** 강조하고 싶으면 볼드 대신 문장 구조·순서·표로 드러낸다.
- daily-works 등 스킬/샘플 포맷에 `**`가 있더라도 쓰지 않는다. 예: `- **Daily works_M/D ~ M/D**` → `- Daily works_M/D ~ M/D`.
- 이탤릭(`*`), 헤더(`#`), 리스트(`-`), 코드(`` ` ``), 표 등 다른 마크다운은 그대로 써도 된다. 금지 대상은 볼드(`**`/`__`)뿐이다.

## 표기·서체 스타일

사용자에게 보여주는 답변과 산출 문서(md·docx·hwp·PDF·슬라이드 등) 전반에 적용한다.

- 가운뎃점(`·`, interpunct) 지양. 항목을 잇거나 나열할 때 `·` 대신 쉼표(`,`)나 "및/과/그리고", 또는 줄바꿈·리스트·표를 쓴다. 예: "구조·순서·표" → "구조, 순서, 표". (경로 구분자나 코드 안 기호처럼 의미가 고정된 곳은 예외.)
- 서체는 고딕체(sans-serif) 계열로 통일하고 궁서체를 비롯한 서체 장식은 쓰지 않는다. 문서 포맷에서 본문 서체를 지정할 때 고딕(예: 맑은 고딕, 나눔고딕, Noto Sans 계열)을 기본으로 한다.
- 불필요한 영어 설명·괄호 번역을 붙이지 않는다. 한국어로 충분히 전달되면 굳이 영어 원어나 번역을 병기하지 않는다. 원어 병기가 실제로 필요한 전문용어·고유명사·처음 등장하는 약어에만 최소한으로 붙인다.
- 캐주얼체보다 공식 문서체를 지향한다. 감탄·구어체·이모지·느낌표 남발을 피하고 중립 명세체(존댓말 명세체 또는 평서체)로 적는다.
- 문서에서 영어를 표기할 때는 특별한 경우를 제외하고 Times New Roman 계열로 통일한다(본문 서체와 별개로 라틴 문자용 서체 지정). 코드·터미널 출력·식별자처럼 고정폭이 필요한 곳은 예외로 고정폭 서체를 쓴다.

## Git

- **메인 계열 브랜치(`main`, `master`, `prod`, `production`, `develop`)는 절대 `git push`를 하지 말 것.** 메인 계열 푸시는 전부 사용자 몫이다. 푸시가 필요하면 푸시하지 말고 사용자에게 "이러이러한 커밋을 push하면 된다"고 알리기만 할 것.
- **워크트리에서 판 서브브랜치(`feat/*`, `fix/*`, `chore/*` 등 작업 브랜치)는 push 해도 된다.** 별도 지시 없이 작업 브랜치를 원격에 push하고 PR까지 만들어도 된다. 단, 그 PR을 **메인 계열로 머지하는 것은 사용자**가 한다.
- 정리: 커밋은 어디서나 가능, **작업 브랜치 push/PR 생성은 허용**, **메인 계열로의 push·머지만 사용자 전용**이다.
- **예외 레포 — `~/.claude`(remote `wim-jax/dot-claude`, 이 전역 설정 백업 레포):** 이 레포는 사용자가 "룰 업데이트/설정 반영해라"고 할 때마다 내가 직접 `main`에 커밋하고 `git push` 하라고 위임한 곳이다. **메인 push 금지 규칙에서 제외** — 설정을 바꾸면 `git add -A && git commit && git push`까지 바로 진행한다(별도 승인 불필요). author는 항상 `jax@wimcorp.co.kr`.

### 참고 문서(레퍼런스) 선(先)커밋

- **레포 밖에서 온 참고 문서(스펙/인터페이스 명세/PDF/도면 등, 예: `~/.claude` 아래나 외부에서 받은 자료)를 레포에 넣고 그걸 근거로 구현·작업을 할 거면, 무조건 그 문서를 제일 먼저 단독 커밋한 뒤에 작업을 시작한다.** 문서를 넣어놓고 구현부터 하다가 문서 커밋을 빠뜨리는 일(예: `docs/OPR_RBQ10_ROS2_Interface.pdf`가 untracked로 방치)을 막기 위함이다.
- 순서: ① 참고 문서를 레포 적절 경로(보통 `docs/`)에 배치 → ② **문서만 담은 커밋 1개**를 먼저 만든다(구현 코드와 섞지 않음) → ③ 그 다음에 그 문서 기반 구현/작업을 진행하고 별도 커밋으로 쌓는다.
- 이유: 구현이 무엇을 근거로 했는지 히스토리에 남기고(문서 커밋이 후속 작업의 앵커), 작업 도중 문서 커밋이 누락되는 사고를 원천 차단한다.
- 워크트리 규칙과 결합: 이 작업도 새 작업이므로 `main` 직접 커밋 금지 대상이다. 먼저 브랜치·워크트리를 판 뒤, 그 워크트리 안에서 **문서 선커밋 → 구현 커밋** 순으로 진행한다.

### 커밋 author/committer (이메일)

- 커밋은 **항상 레포에 설정된 identity**(`git config user.name` / `user.email`, 보통 `jax` / `jax@wimcorp.co.kr`)로 만든다. 개인 Gmail(`ljsung0805@gmail.com` 등)로는 **절대 커밋하지 않는다.**
- **`git -c user.email=...` / `--author`로 author를 덮어쓰지 말 것.** 특히 `git -c user.email="$(git log -1 --format='%ae')"`처럼 **직전 커밋 author를 복사하는 방식 금지** — 직전 커밋이 개인 이메일이면 그대로 딸려와 메인에 박힌다(되돌리려면 메인 히스토리 재작성 = 위험).
- 그냥 `git commit`이면 레포 설정을 쓴다. identity가 안 잡힌 환경이면 명시적으로 `jax@wimcorp.co.kr`을 쓴다. **커밋 직후 `git log -1 --format='%an <%ae>'`로 이메일을 검증**한다.

### 컨플릭 해소 방향 — 역방향 머지 금지

- **작업 브랜치에서 메인 계열(`main`/`master`/`staging`)을 머지해 충돌을 푸는 "역방향 머지"를 하지 않는다.** 브랜치 히스토리에 컨플릭 픽스 커밋을 쌓지 말 것.
- **충돌은 메인 쪽에서 작업 브랜치를 머지할 때, 그 머지 커밋 안에서 해소한다.** 즉 방향은 항상 `메인 ← 브랜치` 한쪽이고, 해소 결과는 메인의 머지 커밋에만 남는다.
- 이유: 작업 브랜치는 "제안된 변경"만 담아야 PR diff가 리뷰 가능하다. 메인 상태를 브랜치로 끌어오면 남의 변경이 diff에 섞여 PR이 읽히지 않고, 같은 충돌을 브랜치마다 반복 해소하게 된다.
- 메인 push/머지는 여전히 사용자 몫이다. 충돌이 있으면 **로컬에서 메인 쪽 머지를 준비해 충돌만 풀어두고, 사용자에게 "이 머지를 push/PR 머지하면 된다"고 알린다.** 에이전트가 메인에 push하지 않는다.
- 이미 브랜치에 역방향 머지 커밋을 만들어 push했다면, 되돌리는 force-push는 **사용자 확인을 받고** 진행한다.
- **PR을 로컬에서 머지할 때 커밋 메시지는 GitHub 머지 커밋 포맷과 동일하게** 만든다. 제목은 `Merge pull request #<번호> from <owner>/<브랜치>`, 빈 줄, 그 다음 줄에 PR 제목. 충돌 해소 근거 등 부연은 그 아래 본문에 적는다. `--no-ff`로 머지 커밋을 반드시 남긴다(fast-forward 금지).
  ```
  Merge pull request #9 from WIM-Corporation/collector-interface-doc

  docs(D49): 전달본 정리 + SSD 영속 저장 복원, MQTT publish 명확화

  <충돌 해소 방식·채택 근거 등 부연>
  ```
  이유: 로컬 머지든 GitHub 버튼이든 히스토리 모양이 같아야 `git log`에서 PR 경계를 일관되게 읽을 수 있고, 어느 PR이 어디서 들어왔는지 추적된다.

### 브랜치 삭제 정책

- **기준은 복원 가능성.** PR을 **merge-commit**으로 머지하면 브랜치 tip 커밋이 메인 히스토리에 남으므로(머지 커밋의 부모, 메시지에 브랜치명 기록) `git branch <name> <sha>`로 무손실 복원이 가능하다. 따라서 이렇게 **메인에 fully-merged된 브랜치는 삭제해도 된다.**
- **삭제 OK 판정:** `gh api repos/.../compare/<default>...<branch> --jq .ahead_by == 0` (또는 로컬 `git branch --merged origin/<default>`). origin·local 모두 이 기준으로 일괄 삭제 가능. 단일 머지 직후 즉시 자동삭제는 자제(in-flight fixup 여지)하되, **사용자가 정리를 요청하면 이 기준으로 origin+local 일괄 삭제한다.**
- **보존(삭제 금지):** ① **미머지**(ahead_by>0 = 메인에 없는 커밋 보유 = 유실 위험) ② **squash-only 머지**(원본 커밋이 메인에 없어 메인 히스토리로 복원 불가 — ahead_by로는 미머지처럼 보여 자동 대상에서 자연 제외됨) ③ **protected**(main/master/develop/prod/production/staging 및 각 레포 default 브랜치) ④ **CI 인프라 브랜치**(아래 `hotfix-base` 등 — 빌드 시스템의 VCS root default/base로 참조되는 브랜치. 머지되어 ahead==0으로 보여도 지우면 CI가 깨진다).
- 🚨 **`hotfix-base`(wim_backoffice 엄브렐러) 절대 삭제 금지** — TeamCity `Hotfix` 프로젝트(Backend/KbService/Wimmy 잡)의 VCS root(`WimBackoffice_HotfixVcs`) **default 브랜치**다. 이게 원격에 없으면 모든 `hotfix/*` 빌드가 change collection 단계("Cannot find revision of the default branch 'hotfix-base'")에서 실패한다(실제 사고: 2026-08-03 삭제돼 v1.12.25 핫픽스 빌드 3회 실패). **머지 완료된 것처럼 보여도(ahead==0) 브랜치 일괄정리 대상에서 제외**한다. 실수로 지웠으면 **직전 head SHA로 복원**(현 main tip으로 리셋하지 말 것 — hotfix-base는 릴리스/직전 핫픽스 베이스를 가리키는 안정 기준점이다. 마지막 값은 TeamCity 최근 Hotfix 빌드의 `revisions`에서 `vcsBranchName=refs/heads/hotfix-base`인 리비전으로 확인).
- **항상 fully-merged(ahead==0)만** 지우고 미머지는 절대 건드리지 않는다. default 브랜치가 비표준인 레포(예: default가 `feat/*`)는 자동 대상에서 빼고 사용자에게 확인한다.

## 워크트리 & 작업 격리

- **새 작업은 문서든 코드든 `main`(또는 현재 메인 디렉터리 브랜치)에 직접 커밋하지 말 것.** 기능 개발·버그 픽스 등 작업할 내용에 대한 spec/plan 문서를 작성하면, 그 자체가 작업 시작이다. **반드시 먼저 브랜치를 파서 워크트리로 옮긴 뒤** 그 안에서 문서·코드를 커밋한다. 명시적 지시가 없어도 기본 동작이다.
  - 워크트리 위치·네이밍: 메인 repo **내부**의 `<repoDir>/.worktrees/<branchName>/` (브랜치명을 그대로 경로로 사용, `/` 치환·`worktree-` prefix 금지, repo 외부 형제 디렉터리 금지). `.worktrees/`는 `.gitignore`에 등록되어 추적 제외된다.
  - 첫 작업으로 `git worktree add .worktrees/<branch> -b <branch>`를 실행하고, 이후 모든 작업(브레인스토밍/설계 문서 포함)을 그 경로에서 수행한다. 메인 디렉터리에서 `git checkout -b`로 브랜치를 갈아치우지 말 것(타 세션 격리).
  - **워크트리 브랜치의 upstream은 절대 메인 계열(`origin/staging`·`origin/master`·`origin/main` 등)로 두지 말 것.** start-point로 메인 브랜치에서 분기하더라도 그 메인 브랜치가 upstream으로 잡히면 안 된다(그냥 `git push` 시 자기 브랜치가 아니라 메인 브랜치를 밀려다 실패/오작동함). 분기는 반드시 `--no-track`으로 한다:
    - `git worktree add .worktrees/<branch> -b <branch> --no-track origin/staging` (start-point는 분기 기준일 뿐, 추적 대상이 아님)
    - 만약 이미 upstream이 메인으로 잡혔다면 `git branch --unset-upstream`으로 끊는다.
  - **push는 항상 자기 브랜치를 명시**해 upstream을 자기 자신으로 만든다: `git push -u origin <branch>`. 인자 없는 `git push`에 의존하지 말 것.

- **워크트리에서 로컬 테스트가 곧바로 가능하도록 실행 환경을 링크로 구성한다.** 워크트리를 만들면 의존성/빌드 산출물처럼 무겁거나 환경에 종속된 디렉터리를 메인 작업 디렉터리에서 심볼릭 링크로 연결해, 재설치·재빌드 없이 바로 실행/테스트할 수 있게 한다.
  - 예: Node 프로젝트는 `node_modules/`를 링크 (`ln -s <repoDir>/node_modules <repoDir>/.worktrees/<branch>/node_modules`).
  - 그 외에도 프로젝트별로 `.env`/로컬 설정, 빌드 캐시(`.gradle`, `build/`, `target/`, `.venv`, `dist/` 등), 대용량 데이터/모델 디렉터리 등 재생성 비용이 큰 것들을 같은 방식으로 링크한다.
  - 단, 워크트리별로 격리되어야 하는 것(소스 코드, git 메타데이터 등)은 링크하지 말 것.

## 슈퍼파워(superpowers) 문서 위치

- superpowers 스킬이 생성하는 문서는 작업 디렉터리 하위의 정해진 경로에 만든다.
  - **스펙(spec) 문서**(brainstorming/writing-specs 등의 결과물): `<work-dir>/docs/specs/`
  - **계획(plan) 문서**(writing-plans 등의 결과물): `<work-dir>/docs/plans/`
- `<work-dir>`는 해당 작업의 프로젝트 루트(예: 모노레포 내 개별 패키지 루트)를 가리킨다. 리포지토리 최상위가 아니라 실제 작업 중인 프로젝트 기준으로 잡는다.
- 파일명은 날짜 프리픽스를 붙인다: `YYYY-MM-DD-<제목>.md` (예: `2026-06-10-cloudflare-pages-migration-design.md`).

## 파일 경로 보고 방식

- **사용자에게 파일 위치를 알릴 때는 메인 레포 루트 기준 상대 경로를 쓰되, 워크트리 안의 파일이면 워크트리 prefix(`.worktrees/<branch>/...`)를 포함한다.** 절대 경로(`/Users/...`)도, 워크트리 prefix가 빠진 레포 상대 경로(`docs/plans/...`)도 아니다. prefix가 빠지면 사용자가 워크트리 폴더를 직접 찾아 들어가야 해서 불편하다.
- 예: `docs/plans/2026-07-30-x.md` (X, prefix 빠짐) / `/Users/jax/workspace/out-sourcing/mando-hsr-sdk/.worktrees/feat/foo/docs/plans/2026-07-30-x.md` (X, 절대경로) → `.worktrees/feat/foo/docs/plans/2026-07-30-x.md` (O).
- 커밋 메시지·diff·코드 내 참조 등은 종전대로(해당 워크트리 기준 경로). 이 규칙은 **사용자가 열어보라고 안내하는 경로**에만 적용된다.

## 1패스 품질 (반복 루프 비용 줄이기)

사용자가 `review-until-converged` 같은 수렴 루프를 도는 근본 원인은 **1패스 결과물의 품질 부족**이다. 루프는 그 부족분을 토큰으로 메우는 비효율이므로, 첫 패스에서 결함을 걷어내 루프를 "결함 메우기"가 아니라 "취향·세부 조정" 수준으로 낮춘다. 사소한 단발 작업이 아닌 한, 기능 개발·버그 픽스·리팩터에 기본 적용한다.

- **코드 손대기 전에 수용 기준을 명시한다.** "이 조건들이 다 충족이면 done"을 먼저 적고(가능하면 사용자 승인을 받고) 그 기준을 향해 구현한다. 모호한 채로 일단 짜고 리뷰로 메우는 패턴이 반복의 최대 원인이다.
- **엣지케이스·실패경로를 처음부터 테이블에 올린다.** 본문 다 짜고 나서 떠올리지 말 것.
- **1패스 끝나면 셀프 비평 1회를 자동으로 돌린다.** 작성과 같은 컨텍스트에서 보면 자기 결함이 안 보이므로, 별도 에이전트(`code-reviewer`/`critic`/`verifier`)나 깨끗한 컨텍스트로 명백한 결함을 걷어낸 뒤 사용자에게 넘긴다. 같은 활성 컨텍스트에서의 셀프 승인은 금지(전역 verification 원칙과 동일).
- 결과물을 넘길 때, 충족한 수용 기준과 남은 트레이드오프/불확실성을 함께 보고해 사용자가 무엇을 더 볼지 빠르게 판단하게 한다.

## 문서 작성 스타일 (플랫·사실 위주, 홍보/LLM-슬롭 금지)

**모든 산출 문서(스펙·명세·README·계약서·거래처 전달본·설계/계획 문서·보고서 등)에 무조건 적용한다.** 문서는 "정보를 전달"하는 것이지 무언가를 "홍보·설득"하는 게 아니다. LLM 특유의 과장·자화자찬·마케팅 톤은 전부 제거하고, 읽는 사람이 사실을 빠르게 파악하도록 **플랫하게(flat)** 적는다. 특히 거래처/외부 전달 문서에서 이 톤이 새어 나가면 회사가 우습게 보인다.

### 금지 (홍보·슬롭 패턴)

- **능력·편의를 파는 문장.** "~만으로 연동할 수 있습니다", "손쉽게/간편하게/빠르게 ~할 수 있습니다", "별도 작업 없이", "코드 변경은 불필요합니다", "~면 충분합니다", "누구나 ~". → 무엇이 있고 어떻게 동작하는지 사실만 적는다. "필요/불필요"를 강조하지 말고 필요한 것만 나열한다.
- **자화자찬·가치 주장 형용사.** "강력한", "혁신적", "손쉬운", "seamless/원활한", "견고한", "유연한", "최적화된", "차세대", "완벽한", "포괄적인". → 형용사로 자랑하지 말고 수치·동작·제약으로 보여준다("최대 1.5 Mbps", "재연결까지 최대 2 s").
- **내용 없는 상투구.** "본 솔루션은 ~를 실현합니다", "~를 통해 가치를 제공합니다", "핵심은 바로 ~입니다", "그뿐만 아니라", "결론적으로 말하자면". → 삭제하고 본론만 남긴다.
- **과장·절대화.** "항상/절대/모든 경우에/완벽히 보장" 같은 무근거 단정. → 실제 조건과 한계를 적는다("현재 1~2 뷰어 전제", "NAT 구간에선 TURN 필요할 수 있음").
- **불필요한 메타 서술.** "이 문서에서는 ~를 다룹니다", "아래에서 자세히 설명하겠습니다" 같은 자기참조. → 목차/제목이 그 역할을 하므로 본문에서 반복하지 않는다.
- **이모지·느낌표 남발·감탄.** 명세/계약 문서엔 이모지·느낌표를 쓰지 않는다.

### 요구 (플랫·상세 스타일)

- **사실·동작·수치·제약만.** 엔드포인트, 스키마, 필드 타입/범위/단위, 기본값, 에러 코드, 경계 동작을 구체적으로. 값에는 항상 단위와 범위를 붙인다(ms, Mbps, fps, 0.0~1.0).
- **자세하고 상세하게.** "플랫"은 "얇게"가 아니다. 연동/재현에 필요한 정보는 빠짐없이(요청/응답 형식, 헤더, 순서, 실패 시 동작, 예시 페이로드). 애매하면 예시를 붙인다.
- **중립 명세체.** 담백한 서술문("~한다/~합니다")으로 통일. 외부 문서는 존댓말 명세체, 내부 문서는 평서체 등 대상에 맞추되 톤은 항상 중립.
- **구조는 스캔 가능하게.** 번호 섹션, 표(필드/타입/설명), 코드블록, 짧은 단락. 산문으로 늘어놓지 말고 표로 정리할 수 있으면 표로.
- **주장 대신 근거.** 성능·안정성을 말해야 하면 형용사가 아니라 측정값·조건으로 적고, 불확실하면 "미측정/추정"이라고 명시한다.

### 외부/거래처 전달 문서 추가 규칙

- **내부 구현 디테일 노출 금지.** 소스 파일 경로, 내부 함수/클래스명, 레포 구조, "우리 코드", 내부 코드네임 등은 외부 문서에서 전부 제거한다. 계약 대상은 네트워크/인터페이스 규격이지 우리 코드가 아니다.
- **회사·제품 명칭은 사용자가 지정한 정식 표기**를 쓰고, 임의 영문 브랜딩("XXX CORPORATION")이나 로고 흉내를 넣지 않는다. 타사에서 받은 문서의 디자인/템플릿(색·로고·레이아웃)을 모방하지 않는다 — 그건 그 회사 자산이다. 형식(섹션 구성)은 참고하되 디자인은 중립으로.
- **1패스 셀프 점검:** 외부 문서를 넘기기 전, 위 금지 패턴을 스스로 1회 grep하듯 훑어 걷어낸 뒤 전달한다.

@RTK.md
