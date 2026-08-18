---
name: github-accounts
description: "gh CLI 계정 2개(개인/회사) — WIM 레포가 \"not found\"면 계정 스위칭"
metadata: 
  node_type: memory
  type: reference
  originSessionId: fa4e2bfe-5ec2-4af9-990e-c772cdc236a3
---

`gh` CLI에 GitHub 계정 2개가 로그인돼 있다:
- **`wim-jax`** — 회사 계정. `WIM-Corporation/*` 조직 레포는 이걸로만 접근/push/PR 됨.
- **`jax-lee-02`** — 개인 계정. WIM 조직 레포 접근 권한 없음.

**증상**: `git fetch`/`gh`가 WIM 레포를 `Repository not found` / `Could not resolve to a Repository`로 실패 → 활성 계정이 개인(`jax-lee-02`)으로 잡힌 것. 레포가 사라진 게 아니다(유실 아님).

**해결**: `gh auth switch --user wim-jax` → 활성 계정 회사로. `gh auth status`로 확인.

WIM 레포 작업(push/PR/fetch) 시작 전 활성 계정이 `wim-jax`인지 확인하면 삽질 방지. 커밋 identity는 별개로 항상 `jax@wimcorp.co.kr`(개인 Gmail 금지) — [[opnsense-network-setup]] 계열 작업 공통.
