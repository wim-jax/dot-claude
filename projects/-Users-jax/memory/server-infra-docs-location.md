---
name: server-infra-docs-location
description: 서버 인프라/신청서 등 서버 관련 문서의 정본 위치 — 구글 드라이브 공유 드라이브
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a82bd60a-14db-442b-9444-8c6e37c988a6
---

서버 관련 문서(서버인프라 구성 md/xlsx, 인천대 사용신청서 등)의 정본(正本)은 구글 드라이브 공유 드라이브에 둔다. 경로:

`/Users/jax/Library/CloudStorage/GoogleDrive-wimmanagement@wimcorp.co.kr/공유 드라이브/인공지능로봇팀/인프라/`

기존 파일: `서버인프라 구성.md`, `서버인프라 구성.xlsx`.

**Why:** 2026-08-12 사용자가 "이제부터 서버 관련 문서 업데이트는 다 구글 드라이브쪽에다 할꺼야"라고 지시. 팀 공유가 목적.

**How to apply:** 서버 관련 문서를 갱신할 때 홈 디렉터리(`/Users/jax/*.md|xlsx`) 사본이 아니라 위 구글 드라이브 경로의 파일을 직접 Read/Edit 한다. 홈 디렉터리 사본은 stale이 될 수 있으니 그쪽에 새로 만들지 말 것. 신규 서버 문서도 이 폴더에 생성.

현재 인프라 구성 요지(2026-08 기준): 경북대 서버실 폐지. GPU 서버 4대(ASUS ESC8000A-E13, 각 GPU 2장) 전부 → 인천대 지능형시스템 설계실습실(8호관 360호) 앵글랙 3번(유세선 교수님)에 서버 4대+라우터 배치(명목 16,000W). CPU 서버 3대(Dell R640) + 네트워크 4대 + UPS(APC SRT3000) → 창업보육센터 사무실 기존 랙.

드라이브 폴더 내 서버 문서: `서버인프라 구성.md`, `서버인프라 구성.xlsx`(시트: 요약/인천대/창업보육센터), `사용신청서_인천대.xlsx`.
