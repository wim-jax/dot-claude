---
name: daily-works
description: Use when the user asks to pull/generate their work log or 작업내역/데일리웍스/daily works report for management (경영팀). Fetches jax's commits from WIM-Backoffice dev-activity API and formats them as a weekly management report.
triggers: ["작업내역", "작업 내용", "daily works", "데일리웍스", "주간보고", "작업보고", "work log"]
---

# Daily Works 보고 생성

이제성(jax) 본인의 작업내역을 WIM-Backoffice dev-activity에서 긁어 **경영팀용 주간 보고**로 정리한다.

## 1. 데이터 수집 (git 직접 긁지 말 것)

`fetch.py`로 커밋을 받는다. 리프레시 토큰이 필요하다.

```bash
python3 ~/.claude/skills/daily-works/fetch.py <FROM> <TO> [REFRESH_TOKEN]
# 예: python3 ~/.claude/skills/daily-works/fetch.py 2026-06-22 2026-07-13 eyJ...
```

- 리프레시 토큰: 사용자가 대화에 붙여주면 그 값을 쓴다. 없으면 환경변수 `WIM_REFRESH_TOKEN`. 둘 다 없으면 **사용자에게 토큰을 요청**한다(민감정보라 저장하지 않음, 만료됨).
- 스크립트가 access token 발급 → calendar → 활동일별 상세를 받아 `날짜 > [레포] > 커밋제목`으로 출력한다.
- dev-activity는 **WIM-Management org 레포만** 인덱싱한다 → plem 계열 등은 안 잡힘. 사용자가 그것까지 원하면 해당 로컬 git 로그를 별도로 합친다.
- 이제성 employeeId(고정): `6c40d177-a63c-46a9-87e9-5005ec96b456`.

## 2. 출력 포맷 (구조 엄수: 요일 > 프로젝트 > 리스트)

주차(Mon~Sun)별로 나눈다. 최근 daily works는 `6/08 ~ 6/14`처럼 월~일 한 주 단위.

```
- Daily works_M/D ~ M/D
    - Mon.
        - [WIM-Backoffice]
            - <이니셔티브 단위 작업>
            - <...>
        - [세아 열화상 모니터링]
            - <...>
    - Tue.
        - [프로젝트]
            - <...>
```

- 볼드(`**`) 금지: 주차 헤더도 `- Daily works_M/D ~ M/D`로만 쓴다(전역 규칙).
- 요일만 표기(Mon./Tue./…). 요일 뒤 날짜는 붙이지 않는다. 활동 없는 요일은 생략.
- 요일 아래에 `[프로젝트]`로 묶고, 그 아래 작업 리스트를 중첩한다.

### 노션 반영
- 사용자는 게스트 계정이라 Notion MCP/인테그레이션 토큰을 못 쓴다(편집자도 봇으로 찍혀 부적합).
- 그래서 결과물은 **노션 붙여넣기용 마크다운**으로 출력한다. 위 포맷 그대로(중첩 불릿) 내면 노션이 붙여넣기 시 중첩 블록으로 자동 변환하고, 편집자는 본인 계정으로 남는다.
- 별도 API 쓰기 없음. 그냥 마크다운을 출력하면 끝.

## 3. 서술 원칙

- 경영팀이 읽는다. **레포/파일/기술 디테일 걷어내고 이니셔티브·비즈니스 가치 단위로 거시적으로** 쓴다. 커밋 나열 금지.
- 하루 수십~수백 커밋을 프로젝트별 2~5개 굵은 테마로 압축한다.

## 4. 프로젝트 표기명 (매핑)

- `wim_backoffice*` (backend/kb-service/frontend/wimmy/prompt_agent 전부) → **WIM-Backoffice**
- `sea-thermal-imaging-monitoring` → **세아 열화상 모니터링**
- `persimmon_pick` → **로봇 자동화(persimmon_pick)**
- `wim_naeo` → **내오(근태 앱)**
- `argo-cd-manifest`, `gpu-monitoring` 등 → **인프라·모니터링**
- `Mando-HSR-SDK` → **Mando-HSR-SDK**
- 그 외는 실제 프로젝트명으로.

이 매핑/포맷은 사용자가 직접 교정해 확정한 것이다. 임의로 바꾸지 말 것.
